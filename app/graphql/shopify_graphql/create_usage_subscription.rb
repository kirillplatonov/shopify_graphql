module ShopifyGraphql
  class CreateUsageSubscription
    include Mutation

    MUTATION = <<~GRAPHQL
      #{AppSubscriptionFields::FRAGMENT}

      mutation appSubscriptionCreate(
        $name: String!,
        $returnUrl: URL!,
        $test: Boolean
        $lineItems: [AppSubscriptionLineItemInput!]!,
      ) {
        appSubscriptionCreate(
          name: $name,
          returnUrl: $returnUrl,
          test: $test
          lineItems: $lineItems,
        ) {
          appSubscription {
            ... AppSubscriptionFields
          }
          confirmationUrl
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def call(name:, return_url:, terms:, capped_amount:, test: false)
      response = execute(
        MUTATION,
        name: name,
        returnUrl: return_url,
        test: test,
        lineItems: [{
          plan: {
            appUsagePricingDetails: {
              terms: terms,
              cappedAmount: {amount: capped_amount, currencyCode: "USD"}
            }
          }
        }]
      )
      response.data = response.data.appSubscriptionCreate
      handle_user_errors(response.data)
      response.data = parse_data(response.data)
      response
    end

    private

    def parse_data(data)
      OpenStruct.new(
        subscription: AppSubscriptionFields.parse(data.appSubscription),
        confirmation_url: data.confirmationUrl
      )
    end
  end
end
