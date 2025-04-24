require "csv"
require "time"
require_relative "../errors"

module AnPostReturn
  module SFTP
    class TrackingParser
      REQUIRED_FIELDS = %w[tracking_number status timestamp].freeze
      TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S".freeze

      # Parse tracking data from a CSV file
      #
      # @param file [File, Tempfile] CSV file to parse
      # @return [Array<Hash>] Array of tracking data entries
      def self.parse(file)
        new.parse(file)
      end

      # Parse tracking data from a text file
      #
      # @param file_path [String] Path to the text file to parse
      # @return [Hash] Hash containing header, data records, and footer information
      # @raise [AnPostReturn::ParserError] if file is not found or empty
      def parse(file_path)
        validate_file!(file_path)

        result = { header: nil, data: [], footer: nil }

        File.foreach(file_path) do |line|
          line = line.strip
          next if line.empty?

          # Determine delimiter and parse fields
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
            next # Skip unknown record types
          end
        end

        result
      rescue CSV::MalformedCSVError => e
        raise ParserError, "Invalid file format: #{e.message}"
      rescue => e
        raise ParserError, "Error parsing tracking data: #{e.message}"
      end

      private

      def validate_file!(file_path)
        raise ParserError, "File not found: #{file_path}" unless File.exist?(file_path)
        raise ParserError, "Empty file: #{file_path}" if File.zero?(file_path)
      end

      def parse_header(fields)
        {
          record_type: fields[0],
          file_id: fields[1],
          timestamp: format_timestamp(fields[2]),
          record_count: fields[3].to_i,
        }
      end

      def parse_data_record(fields)
        {
          record_type: fields[0],
          service: fields[1],
          tracking_number: fields[2],
          country: fields[3],
          combined_id: fields[4],
          status: fields[5],
          timestamp: format_timestamp(fields[6]),
          location: fields[7],
          notes: fields[8],
          additional_info: fields[9],
          outcome: fields[10],
          recipient: fields[11],
          extra1: fields[12],
          extra2: fields[13],
        }.compact
      end

      def parse_footer(fields)
        { record_type: fields[0], record_count: fields[1].to_i }
      end

      def format_timestamp(timestamp)
        return nil if timestamp.nil? || timestamp.empty?

        if timestamp.length >= 14
          year = timestamp[0..3]
          month = timestamp[4..5]
          day = timestamp[6..7]
          hour = timestamp[8..9]
          minute = timestamp[10..11]
          second = timestamp[12..13]

          Time.new(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, second.to_i)
        else
          Time.parse(timestamp)
        end
      rescue ArgumentError => e
        nil # Return nil for invalid timestamps instead of raising error
      end
    end
  end
end
