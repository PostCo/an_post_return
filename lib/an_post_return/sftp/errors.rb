module AnPostReturn
  module SFTP
    class Error < StandardError
    end
    class ConnectionError < Error
    end
    class FileError < Error
    end
  end
end
