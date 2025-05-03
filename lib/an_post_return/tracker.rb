require_relative "sftp/client"
require_relative "sftp/tracking_parser"
require_relative "configuration"

module AnPostReturn
  class Tracker
    # Initialize a new Tracking resource
    attr_reader :sftp_client
    def initialize
      @config = AnPostReturn.configuration
      @sftp_client =
        SFTP::Client.new(
          @config.sftp_config[:host],
          @config.sftp_config[:username],
          @config.sftp_config[:password],
          @config.proxy_config,
        )
      raise ArgumentError, "SFTP configuration is not set" unless @config.sftp_configured?
    end

    # Track files with a specific account number
    #
    # @param account_number [String] The account number to track
    # @param last [Integer] The number of files to track
    # @yieldparam data [Hash] Parsed tracking data containing :header, :data, and :footer
    # @return [void]
    # @raise [AnPostReturn::SFTP::ConnectionError] if SFTP connection fails
    # @raise [AnPostReturn::SFTP::FileError] if file operations fail
    def track_with_account_number(account_number, last: 0, &block)
      @sftp_client.connect unless @sftp_client.connected?

      # pad the account number with leading zeros to 8 digits
      account_number = account_number.to_s.rjust(8, "0")
      file =
        if last.zero?
          @sftp_client.list_files(@config.sftp_config[:remote_path], "cdt#{account_number}*").first
        else
          @sftp_client.list_files(@config.sftp_config[:remote_path], "cdt#{account_number}*")[-(last + 1)]
        end
      track_from(file.name, &block) if file
    end

    # Get tracking data from a file, incrementing file number if needed
    #
    # @param last_filename  [String, nil] Base last filename processed (e.g. "cdt0370132115864.txt")
    # @param existing_sftp_client [SFTP::Client, nil] Existing SFTP client to use
    # @yieldparam data [Hash] Parsed tracking data containing :header, :data, and :footer
    # @return [void]
    # @raise [AnPostReturn::SFTP::ConnectionError] if SFTP connection fails
    # @raise [AnPostReturn::SFTP::FileError] if file operations fail
    # @raise [AnPostReturn::ParserError] if parsing fails
    def track_from(last_filename, &block)
      return unless block_given?

      @sftp_client.connect unless @sftp_client.connected?

      # example file name: CDT99999999SSSSS.txt
      # Where:
      # •	CDT is to prefix each file (Customer Data Tracking).
      # •	99999999 is the An Post Customer Account Number.
      # •	SSSSS is a sequence number starting at 1 and incrementing by 1 for every file sent, with leading zeros.
      # •	.txt is the standard file extension.
      #
      # extract the customer account number, sequence number and extension
      customer_account_number = last_filename.match(/^cdt(\d+)([0-9]{5})\.txt$/)[1]
      sequence_number = last_filename.match(/^cdt(\d+)([0-9]{5})\.txt$/)[2]
      extension = ".txt"

      while true
        # increment the sequence number
        sequence_number = sequence_number.to_i + 1
        # format the new filename
        next_filename = "cdt#{customer_account_number}#{sequence_number.to_s.rjust(5, "0")}#{extension}"

        @sftp_client.read_file(next_filename) do |tracking_file|
          data = SFTP::TrackingParser.parse(tracking_file)
          yield next_filename, data
        end
      end
    rescue SFTP::FileNotFoundError
      # If file not found, we're done
      return
    end

    def disconnect
      return false unless @sftp_client.connected?

      @sftp_client.disconnect
      true
    end

  end
end
