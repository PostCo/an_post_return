module AnPostReturn
  module SFTP
    class Error < StandardError
    end
    class ConnectionError < Error
    end
    class FileError < Error
    end
    class FileNotFoundError < FileError
    end
  end
end
