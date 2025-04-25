module AnPostReturn
  module Resources
    class ReturnLabel
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Create a return label
      # @param params [Hash] The parameters for creating a return label
      # @option params [String] :output_response_type Type of response ('Label')
      # @option params [Hash] :sender Sender information
      #   @option sender [String] :first_name Sender's first name
      #   @option sender [String] :last_name Sender's last name
      #   @option sender [String] :contact_number Sender's contact number
      #   @option sender [String] :email_address Sender's email address
      # @option params [Hash] :sender_address Sender's address details
      #   @option sender_address [String] :address_line1 First line of address
      #   @option sender_address [String] :address_line2 Second line of address (optional)
      #   @option sender_address [String] :city City
      #   @option sender_address [String] :eircode Eircode
      #   @option sender_address [String] :county County
      #   @option sender_address [String] :country Country name
      #   @option sender_address [String] :countrycode Country code (ISO 3166-1 alpha-2)
      # @option params [String] :retailer_account_no Your An Post account number
      # @option params [String] :retailer_return_reason Reason for return
      # @option params [String] :retailer_order_number Order number
      # @option params [Array<Hash>] :international_security_declaration_items Required for EU returns
      #   @option international_security_declaration_items [String] :item_description Description of item
      # @option params [Hash] :customs_information Required for non-EU returns
      #   @option customs_information [String] :customs_region_code Customs region code
      #   @option customs_information [Integer] :customs_category_id Category ID
      #   @option customs_information [Float] :weight Weight in kg
      #   @option customs_information [Float] :value_amount Value amount
      #   @option customs_information [Float] :postage_fee_paid Postage fee paid
      #   @option customs_information [Float] :insured_value Insured value
      #   @option customs_information [Array<Hash>] :customs_content_items Content items for customs
      #     @option customs_content_items [Integer] :list_order Order in list
      #     @option customs_content_items [Integer] :number_of_units Number of units
      #     @option customs_content_items [String] :description Item description
      #     @option customs_content_items [String] :hs_tarriff HS tariff code
      #     @option customs_content_items [Float] :value_amount Item value
      #     @option customs_content_items [Float] :weight Item weight
      #     @option customs_content_items [String] :country_of_origin Country of origin code
      # @return [Hash] The created return label data
      #
      # @example Create a domestic return label
      #   client.return_labels.create({
      #     output_response_type: "Label",
      #     sender: {
      #       first_name: "Jane",
      #       last_name: "Smith",
      #       contact_number: "0871234567",
      #       email_address: "test@email.com"
      #     },
      #     sender_address: {
      #       address_line1: "Exo Building",
      #       address_line2: "North Wall Quay",
      #       city: "Dublin 1",
      #       eircode: "D01 W5Y2",
      #       county: "Dublin",
      #       country: "Ireland",
      #       countrycode: "IE"
      #     },
      #     retailer_account_no: "your_account_number",
      #     retailer_return_reason: "Does not fit",
      #     retailer_order_number: "987654321"
      #   })
      #
      # @example Create an EU return label
      #   client.return_labels.create({
      #     output_response_type: "Label",
      #     sender: { ... },
      #     sender_address: { ... },
      #     international_security_declaration_items: [
      #       { item_description: "book" }
      #     ],
      #     retailer_account_no: "your_account_number",
      #     retailer_return_reason: "Does not fit",
      #     retailer_order_number: "123456789"
      #   })
      #
      # @example Create a non-EU return label
      #   client.return_labels.create({
      #     customs_information: {
      #       customs_region_code: "1",
      #       customs_category_id: 2,
      #       weight: 1.5,
      #       value_amount: 55,
      #       postage_fee_paid: 1,
      #       insured_value: 55,
      #       customs_content_items: [
      #         {
      #           list_order: 1,
      #           number_of_units: 1,
      #           description: "shoes",
      #           hs_tarriff: "6404191000",
      #           value_amount: 55,
      #           weight: 1.5,
      #           country_of_origin: "IE"
      #         }
      #       ]
      #     },
      #     output_response_type: "Label",
      #     sender: { ... },
      #     sender_address: { ... },
      #     retailer_account_no: "your_account_number",
      #     retailer_return_reason: "Does not fit",
      #     retailer_order_number: "321654987"
      #   })
      def create(params)
        raise ArgumentError, "Missing required parameters" if params.nil?
        raise ArgumentError, "Subscription key not configured" if client.config.subscription_key.nil?

        response = client.connection.post("returnsLabel") { |req| req.body = params }
        client.send(:handle_response, response)
      end
    end
  end
end
