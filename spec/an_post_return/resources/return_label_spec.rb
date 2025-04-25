require "spec_helper"
# require "an_post_return/resources/return_label"

RSpec.describe AnPostReturn::Resources::ReturnLabelResource do
  let(:subscription_key) { "test_subscription_key" }
  let(:client) { AnPostReturn::Client.new }
  let(:return_label) { described_class.new(client) }

  before { AnPostReturn.configure { |config| config.subscription_key = subscription_key } }

  after { AnPostReturn.configure { |config| config.subscription_key = nil } }

  describe "#create" do
    let(:base_params) do
      {
        output_response_type: "Label",
        sender: {
          first_name: "Jane",
          last_name: "Smith",
          contact_number: "0871234567",
          email_address: "test@email.com",
        },
        sender_address: {
          address_line1: "Exo Building",
          address_line2: "North Wall Quay",
          city: "Dublin 1",
          eircode: "D01 W5Y2",
          county: "Dublin",
          country: "Ireland",
          countrycode: "IE",
        },
        retailer_account_no: "test_account",
        retailer_return_reason: "Does not fit",
        retailer_order_number: "987654321",
      }
    end

    let(:success_response) do
      {
        "trackingNumber" => "CH000100026IE",
        "labelData" => "[PDF bitstream]",
        "posLabelPrintingBarcode" => "PSS502177250027472",
        "success" => true,
        "transactionReference" => "PSS50217725",
        "errors" => [],
      }
    end

    let(:headers) do
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Ocp-Apim-Subscription-Key" => subscription_key,
      }
    end

    context "when creating a domestic return label" do
      before do
        stub_request(:post, "#{client.config.api_base_url}/returnsLabel").with(
          body: base_params,
          headers: headers,
        ).to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "sends the correct request and returns a ReturnLabel object" do
        result = return_label.create(base_params)
        expect(result).to be_a(AnPostReturn::ReturnLabel)
        expect(result.tracking_number).to eq("CH000100026IE")
        expect(result.label_data).to eq("[PDF bitstream]")
        expect(result.pos_label_printing_barcode).to eq("PSS502177250027472")
        expect(result.success).to be true
        expect(result.transaction_reference).to eq("PSS50217725")
        expect(result.errors).to be_empty
      end
    end

    context "when creating an EU return label" do
      let(:eu_params) { base_params.merge(international_security_declaration_items: [{ item_description: "book" }]) }

      before do
        stub_request(:post, "#{client.config.api_base_url}/returnsLabel").with(
          body: eu_params,
          headers: headers,
        ).to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "sends the correct request and returns a ReturnLabel object" do
        result = return_label.create(eu_params)
        expect(result).to be_a(AnPostReturn::ReturnLabel)
        expect(result.tracking_number).to eq("CH000100026IE")
        expect(result.label_data).to eq("[PDF bitstream]")
        expect(result.pos_label_printing_barcode).to eq("PSS502177250027472")
        expect(result.success).to be true
        expect(result.transaction_reference).to eq("PSS50217725")
        expect(result.errors).to be_empty
      end
    end

    context "when creating a non-EU return label" do
      let(:non_eu_params) do
        base_params.merge(
          customs_information: {
            customs_region_code: "1",
            customs_category_id: 2,
            weight: 1.5,
            value_amount: 55,
            postage_fee_paid: 1,
            insured_value: 55,
            customs_content_items: [
              {
                list_order: 1,
                number_of_units: 1,
                description: "shoes",
                hs_tarriff: "6404191000",
                value_amount: 55,
                weight: 1.5,
                country_of_origin: "IE",
              },
            ],
          },
        )
      end

      before do
        stub_request(:post, "#{client.config.api_base_url}/returnsLabel").with(
          body: non_eu_params,
          headers: headers,
        ).to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "sends the correct request and returns a ReturnLabel object" do
        result = return_label.create(non_eu_params)
        expect(result).to be_a(AnPostReturn::ReturnLabel)
        expect(result.tracking_number).to eq("CH000100026IE")
        expect(result.label_data).to eq("[PDF bitstream]")
        expect(result.pos_label_printing_barcode).to eq("PSS502177250027472")
        expect(result.success).to be true
        expect(result.transaction_reference).to eq("PSS50217725")
        expect(result.errors).to be_empty
      end
    end

    context "when the API returns an error with status 400" do
      let(:error_response) do
        {
          "trackingNumber" => nil,
          "collectionDate" => nil,
          "success" => false,
          "transactionReference" => nil,
          "errors" => [{ "message" => "The Direct Returns Retailer with Account Number: 37408681 cannot be found" }],
        }
      end

      before do
        stub_request(:post, "#{client.config.api_base_url}/returnsLabel").with(
          body: base_params,
          headers: headers,
        ).to_return(status: 400, body: error_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "raises an APIError" do
        expect { return_label.create(base_params) }.to raise_error(
          AnPostReturn::ValidationError,
          "The Direct Returns Retailer with Account Number: 37408681 cannot be found",
        )
      end
    end

    context "when the API returns an error with status 200" do
      let(:error_response) { { "success" => false, "errors" => [{ "message" => "Invalid parameters" }] } }

      before do
        stub_request(:post, "#{client.config.api_base_url}/returnsLabel").with(
          body: base_params,
          headers: headers,
        ).to_return(status: 200, body: error_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "raises an APIError" do
        expect { return_label.create(base_params) }.to raise_error(
          AnPostReturn::APIError,
          "API request failed with status 200: Invalid parameters",
        )
      end
    end
  end
end
