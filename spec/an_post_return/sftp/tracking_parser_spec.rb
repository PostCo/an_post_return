require "spec_helper"
require "an_post_return/sftp/tracking_parser"
require "tempfile"

RSpec.describe AnPostReturn::SFTP::TrackingParser do
  let(:parser) { described_class.new }
  let(:valid_content) { <<~TXT }
      00,FILE001,20240320143000,2
      01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin,Notes here,Additional info,Success,John Doe,Extra1,Extra2
      01,STD,CD987654321IE,IE,COMB002,In Transit,20240320101500,Cork,In transit,More info,Pending,Jane Smith,Extra3,Extra4
      99,2
    TXT

  describe "#parse" do
    context "with valid data" do
      it "successfully parses tracking data" do
        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(valid_content)
          file.rewind

          result = parser.parse(file.path)

          # Check header
          expect(result[:header]).to include(
            record_type: "00",
            file_id: "FILE001",
            timestamp: Time.new(2024, 3, 20, 14, 30, 0),
            record_count: 2,
          )

          # Check data records
          expect(result[:data].size).to eq(2)
          first_record = result[:data].first
          expect(first_record).to include(
            record_type: "01",
            service: "STD",
            tracking_number: "AB123456789IE",
            country: "IE",
            combined_id: "COMB001",
            status: "Delivered",
            timestamp: Time.new(2024, 3, 20, 14, 30, 0),
            location: "Dublin",
          )

          # Check footer
          expect(result[:footer]).to include(record_type: "99", record_count: 2)
        ensure
          file.close
          file.unlink
        end
      end

      it "handles alternative delimiter (+)" do
        content = <<~TXT
          00+FILE001+20240320143000+1
          01+STD+AB123456789IE+IE+COMB001+Delivered+20240320143000+Dublin+Notes+Info+Success+John+Extra1+Extra2
          99+1
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          result = parser.parse(file.path)
          expect(result[:data].first[:tracking_number]).to eq("AB123456789IE")
        ensure
          file.close
          file.unlink
        end
      end
    end

    context "with invalid data" do
      it "skips unknown record types" do
        content = <<~TXT
          00,FILE001,20240320143000,1
          02,INVALID,RECORD,TYPE
          01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin
          99,1
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          result = parser.parse(file.path)
          expect(result[:data].size).to eq(1)
          expect(result[:data].first[:tracking_number]).to eq("AB123456789IE")
        ensure
          file.close
          file.unlink
        end
      end

      it "returns nil header when header is missing" do
        content = <<~TXT
          01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin
          99,1
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          result = parser.parse(file.path)
          expect(result[:header]).to be_nil
          expect(result[:data].size).to eq(1)
        ensure
          file.close
          file.unlink
        end
      end

      it "returns nil footer when footer is missing" do
        content = <<~TXT
          00,FILE001,20240320143000,1
          01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          result = parser.parse(file.path)
          expect(result[:footer]).to be_nil
          expect(result[:data].size).to eq(1)
        ensure
          file.close
          file.unlink
        end
      end

      it "returns empty data array when no data records exist" do
        content = <<~TXT
          00,FILE001,20240320143000,0
          99,0
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          result = parser.parse(file.path)
          expect(result[:data]).to be_empty
        ensure
          file.close
          file.unlink
        end
      end

      it "handles invalid timestamps by returning nil" do
        content = <<~TXT
          00,FILE001,invalid_time,1
          01,STD,AB123456789IE,IE,COMB001,Delivered,invalid_time,Dublin
          99,1
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          result = parser.parse(file.path)
          expect(result[:header][:timestamp]).to be_nil
          expect(result[:data].first[:timestamp]).to be_nil
        ensure
          file.close
          file.unlink
        end
      end
    end

    context "with file handling" do
      it "raises ParserError for non-existent file" do
        expect { parser.parse("nonexistent.txt") }.to raise_error(AnPostReturn::ParserError, /File not found/)
      end

      it "raises ParserError for empty file" do
        file = Tempfile.new(%w[tracking .txt])
        begin
          expect { parser.parse(file.path) }.to raise_error(AnPostReturn::ParserError, /Empty file/)
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
