require "net/sftp"
require "pry"
require "uri"
require "net/ssh/proxy/http"
require "x25519"
require "tempfile"
require "csv"

class SFTPClient
  def initialize(host, user, password, http_proxy_config = nil)
    @host = host
    @user = user
    @password = password
    @http_proxy_config = http_proxy_config
  end

  def connect
    sftp_client.connect!
  rescue Net::SSH::Exception => e
    puts "Failed to connect to #{@host}"
    puts e.message
  end

  def disconnect
    sftp_client.close_channel
    ssh_session.close
  end

  def read_file(remote_path, &block)
    temp_file = Tempfile.new(["sftp", File.extname(remote_path)])
    begin
      @sftp_client.download!(remote_path, temp_file.path)
      block_given? ? block.call(temp_file) : temp_file
    rescue Net::SFTP::StatusException => e
      puts "Failed to download #{remote_path}: #{e.message}"
      nil
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def list_files(remote_path, glob_pattern = nil)
    if glob_pattern
      @sftp_client.dir.glob(remote_path, glob_pattern).each { |entry| puts entry.longname }
    else
      @sftp_client.dir.foreach(remote_path) { |entry| puts entry.longname }
    end
  end

  def sftp_client
    @sftp_client ||= Net::SFTP::Session.new(ssh_session)
  end

  private

  def ssh_session
    ssh_options = { password: @password, auth_methods: ["password"] }

    # Add proxy configuration if provided
    if @http_proxy_config
      ssh_options[:proxy] = Net::SSH::Proxy::HTTP.new(
        @http_proxy_config[:host],
        @http_proxy_config[:port],
        user: @http_proxy_config[:username],
        password: @http_proxy_config[:password],
      )
    end

    @ssh_session ||= Net::SSH.start(@host, @user, ssh_options)
  end
end

class TrackingDataParser
  def initialize(file_path)
    @file_path = file_path
  end

  def parse
    result = { header: nil, data: [], footer: nil }

    File.foreach(@file_path) do |line|
      line = line.strip
      next if line.empty?

      # Determine delimiter and parse with CSV to handle quoted fields
      delimiter = line.include?("+") ? "+" : ","
      fields = CSV.parse_line(line, col_sep: delimiter, quote_char: '"')
      record_type = fields[0]

      case record_type
      when "00"
        result[:header] = parse_header(fields)
      when "01"
        result[:data] << parse_data_record(fields)
      when "99"
        result[:footer] = parse_footer(fields)
      else
        puts "Warning: Unknown record type: #{record_type}"
      end
    end

    result
  end

  private

  def parse_header(fields)
    { record_type: fields[0], file_id: fields[1], timestamp: fields[2], record_count: fields[3].to_i }
  end

  def parse_data_record(fields)
    {
      record_type: fields[0],
      service: fields[1],
      tracking_number: fields[2],
      country: fields[3],
      combined_id: fields[4],
      status: fields[5],
      timestamp: fields[6],
      location: fields[7],
      notes: fields[8],
      additional_info: fields[9],
      outcome: fields[10],
      recipient: fields[11],
      extra1: fields[12],
      extra2: fields[13],
    }
  end

  def parse_footer(fields)
    { record_type: fields[0], record_count: fields[1].to_i }
  end

  def format_timestamp(timestamp)
    return nil if timestamp.nil?

    if timestamp.length >= 14
      year = timestamp[0..3]
      month = timestamp[4..5]
      day = timestamp[6..7]
      hour = timestamp[8..9]
      minute = timestamp[10..11]
      second = timestamp[12..13]

      "#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}"
    else
      timestamp
    end
  end
end

# Example proxy configuration
http_proxy_config = {
  host: "sgp-forward-proxy.postco.co",
  port: 3128,
  username: "proxyuser", # Optional for HTTP
  password: "VG17nL@qYgAFts", # Optional for HTTP
}

start_time = Time.now
# With proxy
sftp = SFTPClient.new("anpost.moveitcloud.eu", "ctuserpostco", "nUVG<akG[4@vc}^o", http_proxy_config)
sftp.connect
end_time = Time.now
puts "Time taken to connect: #{end_time - start_time} seconds"

# Rest of your code remains the same
# sftp.list_files("/home/ctuserpostco", "cdt03795540083[4-9]*.txt")

start = 379_554_008_300
statuses = Set.new
# increment by 1 for 10 times
100.times do
  file_name = "cdt0#{start += 1}.txt"
  sftp.read_file("#{file_name}") do |temp_file|
    parser = TrackingDataParser.new(temp_file.path)
    data = parser.parse
    data[:data].each { |record| statuses.add(record[:status]) }
  end
end

puts "Statuses: #{statuses.size}"

sftp.disconnect
