require_relative "../sftp/client"
require_relative "../sftp/tracking_parser"

module AnPostReturn
  module Resources
    class Tracking
      # Initialize a new Tracking resource
      #
      # @param host [String] SFTP server hostname
      # @param username [String] SFTP username
      # @param password [String] SFTP password
      # @param remote_path [String] Base remote path for tracking files
      # @param http_proxy_url [String, nil] Optional HTTP proxy URL, overrides configuration
      def initialize(host:, username:, password:, remote_path:, http_proxy_url: nil)
        @host = host
        @username = username
        @password = password
        @remote_path = remote_path
        @http_proxy_url = http_proxy_url
      end

      # Get tracking data from the latest file
      #
      # @return [Hash] Parsed tracking data
      # @raise [AnPostReturn::SFTP::ConnectionError] if SFTP connection fails
      # @raise [AnPostReturn::SFTP::FileError] if file operations fail
      # @raise [AnPostReturn::ParserError] if parsing fails
      def latest_tracking_data
        with_sftp_client do |client|
          files = client.list_files(@remote_path)
          latest_file = find_latest_file(files)

          raise SFTP::FileError, "No tracking files found in #{@remote_path}" if latest_file.nil?

          client.read_file(File.join(@remote_path, latest_file.name)) do |temp_file|
            SFTP::TrackingParser.parse(temp_file)
          end
        end
      end

      # Get tracking data from a specific file
      #
      # @param filename [String] Name of the tracking file to process
      # @return [Hash] Parsed tracking data
      # @raise [AnPostReturn::SFTP::ConnectionError] if SFTP connection fails
      # @raise [AnPostReturn::SFTP::FileError] if file operations fail
      # @raise [AnPostReturn::ParserError] if parsing fails
      def tracking_data_for_file(filename)
        with_sftp_client do |client|
          client.read_file(File.join(@remote_path, filename)) { |temp_file| SFTP::TrackingParser.parse(temp_file) }
        end
      end

      # List available tracking files
      #
      # @param pattern [String] Optional glob pattern to filter files
      # @return [Array<String>] List of tracking file names
      # @raise [AnPostReturn::SFTP::ConnectionError] if SFTP connection fails
      # @raise [AnPostReturn::SFTP::FileError] if listing fails
      def list_tracking_files(pattern: "*")
        with_sftp_client do |client|
          files = client.list_files(@remote_path, pattern)
          files.map(&:name)
        end
      end

      private

      def with_sftp_client
        client =
          SFTP::Client.new(host: @host, username: @username, password: @password, http_proxy_url: @http_proxy_url)
        client.connect
        yield client
      ensure
        client&.disconnect
      end

      def find_latest_file(files)
        files.max_by { |file| file.attributes.mtime }
      end
    end
  end
end
