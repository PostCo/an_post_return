require_relative "sftp/client"
require_relative "sftp/tracking_parser"
require_relative "configuration"

module AnPostReturn
  class Tracker
    # Initialize a new Tracking resource
    #
    # @param host [String] SFTP server hostname
    # @param username [String] SFTP username
    # @param password [String] SFTP password
    # @param remote_path [String] Base remote path for tracking files
    def initialize(host:, username:, password:, remote_path:)
      @host = host
      @username = username
      @password = password
      @remote_path = remote_path
    end

    # Get tracking data from a file, incrementing file number if needed
    #
    # @param from [String, nil] Base last filename processed (e.g. "cdt0370132115864.txt") or nil to use second last file
    # @yieldparam data [Hash] Parsed tracking data containing :header, :data, and :footer
    # @return [void]
    # @raise [AnPostReturn::SFTP::ConnectionError] if SFTP connection fails
    # @raise [AnPostReturn::SFTP::FileError] if file operations fail
    # @raise [AnPostReturn::ParserError] if parsing fails
    def track(from: nil, &block)
      return unless block_given?

      with_sftp_client do |client|
        filename = if from.nil?
          # second last file
          client.list_files(@remote_path)[-2].name
        else
          from
        end
        # example file name: CDT99999999SSSSS.txt
        # Where:
        # •	CDT is to prefix each file (Customer Data Tracking).
        # •	99999999 is the An Post Customer Account Number.
        # •	SSSSS is a sequence number starting at 1 and incrementing by 1 for every file sent, with leading zeros.
        # •	.txt is the standard file extension.

        # extract the customer account number, sequence number and extension

        customer_account_number= filename.match(/^cdt(\d+)([0-9]{5})\.txt$/)[1]
        sequence_number = filename.match(/^cdt(\d+)([0-9]{5})\.txt$/)[2]
        extension = ".txt"

        while true
          # increment the sequence number
          sequence_number = sequence_number.to_i + 1
          # format the new filename
          next_filename = "cdt#{customer_account_number}#{sequence_number.to_s.rjust(5, "0")}#{extension}"

          client.read_file(next_filename) do |tracking_file|
            data = SFTP::TrackingParser.parse(tracking_file)
            yield tracking_file, data
          end
        end
      end
    rescue SFTP::FileNotFoundError
      # If file not found, we're done
      return
    end

    private

    def with_sftp_client
      config = AnPostReturn.configuration
      client =
        SFTP::Client.new(@host, @username, @password, config.proxy_config)
      client.connect
      yield client
    ensure
      client&.disconnect
    end

  end
end
