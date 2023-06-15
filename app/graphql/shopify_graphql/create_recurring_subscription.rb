module ShopifyGraphql
  class CreateRecurringSubscription
    include Mutation

    MUTATION = <<~GRAPHQL
      #{AppSubscriptionFields::FRAGMENT}

      mutation appSubscriptionCreate(
        $name: String!,
        $lineItems: [AppSubscriptionLineItemInput!]!,
        $returnUrl: URL!,
        $trialDays: Int,
        $test: Boolean
      ) {
        appSubscriptionCreate(
          name: $name,
          lineItems: $lineItems,
          returnUrl: $returnUrl,
          trialDays: $trialDays,
          test: $test
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

    def call(name:, price:, return_url:, trial_days: nil, test: nil, interval: :monthly)
      payload = {name: name, returnUrl: return_url}
      plan_interval = interval == :monthly ? "EVERY_30_DAYS" : "ANNUAL"
      payload[:lineItems] = [{
        plan: {
          appRecurringPricingDetails: {
            price: {amount: price, currencyCode: "USD"},
            interval: plan_interval
          }
        }
      }]
      payload[:trialDays] = trial_days if trial_days
      payload[:test] = test if test

      response = execute(MUTATION, **payload)
      response.data = response.data.appSubscriptionCreate
      handle_user_errors(response.data)
      response.data = parse_data(response.data)
      response
    end

    private

    def parse_data(data)
      Struct
        .new(
          :subscription,
          :confirmation_url
        )
        .new(
          AppSubscriptionFields.parse(data.appSubscription),
          data.confirmationUrl
        )
    end
  end
end
