require "spec_helper"

RSpec.describe AnpostAPI::TrackingDataParser do
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
      it "raises ParserError for unknown record type" do
        content = <<~TXT
          00,FILE001,20240320143000,1
          02,INVALID,RECORD,TYPE
          99,1
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          expect { parser.parse(file.path) }.to raise_error(AnpostAPI::ParserError, /Unknown record type/)
        ensure
          file.close
          file.unlink
        end
      end

      it "raises ParserError for missing header" do
        content = <<~TXT
          01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin
          99,1
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          expect { parser.parse(file.path) }.to raise_error(AnpostAPI::ParserError, /Missing header/)
        ensure
          file.close
          file.unlink
        end
      end

      it "raises ParserError for missing footer" do
        content = <<~TXT
          00,FILE001,20240320143000,1
          01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          expect { parser.parse(file.path) }.to raise_error(AnpostAPI::ParserError, /Missing footer/)
        ensure
          file.close
          file.unlink
        end
      end

      it "raises ParserError for record count mismatch" do
        content = <<~TXT
          00,FILE001,20240320143000,2
          01,STD,AB123456789IE,IE,COMB001,Delivered,20240320143000,Dublin
          99,2
        TXT

        file = Tempfile.new(%w[tracking .txt])
        begin
          file.write(content)
          file.rewind

          expect { parser.parse(file.path) }.to raise_error(AnpostAPI::ParserError, /Record count mismatch/)
        ensure
          file.close
          file.unlink
        end
      end
    end

    context "with file handling" do
      it "raises ParserError for non-existent file" do
        expect { parser.parse("nonexistent.txt") }.to raise_error(AnpostAPI::ParserError, /File not found/)
      end

      it "raises ParserError for empty file" do
        file = Tempfile.new(%w[tracking .txt])
        begin
          expect { parser.parse(file.path) }.to raise_error(AnpostAPI::ParserError, /Empty file/)
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
