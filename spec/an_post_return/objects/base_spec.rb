# frozen_string_literal: true

require "spec_helper"

RSpec.describe AnPostReturn::Base do
  describe "initialization and key conversion" do
    let(:camel_case_hash) do
      {
        "trackingNumber" => "CH000100026IE",
        "labelData" => "[PDF bitstream]",
        "posLabelPrintingBarcode" => "PSS502177250027472",
        "success" => true,
        "transactionReference" => "PSS50217725",
        "errors" => [],
        "nestedObject" => {
          "innerCamelCase" => "value",
        },
        "itemsList" => [{ "listItemId" => 1 }, { "listItemId" => 2 }],
      }
    end

    subject(:base_object) { described_class.new(camel_case_hash) }

    it "converts camelCase keys to snake_case for object attributes" do
      expect(base_object.tracking_number).to eq("CH000100026IE")
      expect(base_object.label_data).to eq("[PDF bitstream]")
      expect(base_object.pos_label_printing_barcode).to eq("PSS502177250027472")
      expect(base_object.success).to be true
      expect(base_object.transaction_reference).to eq("PSS50217725")
      expect(base_object.errors).to be_empty
    end

    it "converts nested objects' keys to snake_case" do
      expect(base_object.nested_object.inner_camel_case).to eq("value")
    end

    it "converts keys in array items to snake_case" do
      expect(base_object.items_list[0].list_item_id).to eq(1)
      expect(base_object.items_list[1].list_item_id).to eq(2)
    end

    it "preserves the original response with camelCase keys" do
      expect(base_object.response).to eq(camel_case_hash)
      expect(base_object.original_response).to eq(camel_case_hash)

      # Verify camelCase keys are preserved
      expect(base_object.response["trackingNumber"]).to eq("CH000100026IE")
      expect(base_object.response["posLabelPrintingBarcode"]).to eq("PSS502177250027472")
      expect(base_object.response["nestedObject"]["innerCamelCase"]).to eq("value")
      expect(base_object.response["itemsList"][0]["listItemId"]).to eq(1)
    end
  end

  describe "#to_hash" do
    let(:hash) { { "trackingNumber" => "CH000100026IE", "success" => true } }

    subject(:base_object) { described_class.new(hash) }

    it "converts the object back to a hash with snake_case keys" do
      expect(base_object.to_hash).to eq({ "tracking_number" => "CH000100026IE", "success" => true })
    end
  end
end
