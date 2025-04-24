require "net/sftp"
require "net/ssh/proxy/http"
require "tempfile"
require "csv"

module AnPostReturn
  class SFTPClient
    # SFTP connection configuration
    attr_reader :host, :username, :password, :proxy_config

    # Initialize a new SFTP client
    #
    # @param host [String] SFTP server hostname
    # @param username [String] SFTP username
    # @param password [String] SFTP password
    # @param proxy_config [Hash, nil] Optional HTTP proxy configuration
    #   @option proxy_config [String] :host Proxy host
    #   @option proxy_config [Integer] :port Proxy port
    #   @option proxy_config [String, nil] :username Optional proxy username
    #   @option proxy_config [String, nil] :password Optional proxy password
    def initialize(host, username, password, proxy_config = nil)
      @host = host
      @username = username
      @password = password
      @proxy_config = proxy_config
      @connected = false
    end

    # Establish SFTP connection
    #
    # @return [Boolean] true if connection successful, false otherwise
    # @raise [AnPostReturn::ConnectionError] if connection fails
    def connect
      sftp_client.connect!
      @connected = true
      true
    rescue Net::SSH::Exception => e
      raise AnPostReturn::ConnectionError, "Failed to connect to #{host}: #{e.message}"
    end

    # Close SFTP connection
    #
    # @return [void]
    def disconnect
      return unless @connected

      sftp_client.close_channel
      ssh_session.close
      @connected = false
    end

    # Download and read a file from SFTP server
    #
    # @param remote_path [String] Path to file on SFTP server
    # @yield [Tempfile] Temporary file containing downloaded content
    # @return [Tempfile, Object] If block given, returns block result; otherwise returns Tempfile
    # @raise [AnPostReturn::FileError] if file download fails
    def read_file(remote_path)
      ensure_connected
      temp_file = Tempfile.new(["sftp", File.extname(remote_path)])

      begin
        sftp_client.download!(remote_path, temp_file.path)
        block_given? ? yield(temp_file) : temp_file
      rescue Net::SFTP::StatusException => e
        raise AnPostReturn::FileError, "Failed to download #{remote_path}: #{e.message}"
      ensure
        unless block_given?
          temp_file.close
          temp_file.unlink
        end
      end
    end

    # List files in remote directory
    #
    # @param remote_path [String] Remote directory path
    # @param glob_pattern [String, nil] Optional glob pattern for filtering files
    # @return [Array<Net::SFTP::Protocol::V01::Name>] Array of file entries
    # @raise [AnPostReturn::FileError] if listing files fails
    def list_files(remote_path, glob_pattern = nil)
      ensure_connected
      entries = []

      begin
        if glob_pattern
          sftp_client.dir.glob(remote_path, glob_pattern) { |entry| entries << entry }
        else
          sftp_client.dir.foreach(remote_path) { |entry| entries << entry }
        end
        entries
      rescue Net::SFTP::StatusException => e
        raise AnPostReturn::FileError, "Failed to list files in #{remote_path}: #{e.message}"
      end
    end

    private

    def sftp_client
      @sftp_client ||= Net::SFTP::Session.new(ssh_session)
    end

    def ssh_session
      return @ssh_session if @ssh_session

      ssh_options = { password: password, auth_methods: ["password"] }

      if proxy_config
        ssh_options[:proxy] = Net::SSH::Proxy::HTTP.new(
          proxy_config[:host],
          proxy_config[:port],
          user: proxy_config[:username],
          password: proxy_config[:password],
        )
      end

      @ssh_session = Net::SSH.start(host, username, ssh_options)
    end

    def ensure_connected
      raise AnPostReturn::ConnectionError, "Not connected to SFTP server" unless @connected
    end
  end
end
