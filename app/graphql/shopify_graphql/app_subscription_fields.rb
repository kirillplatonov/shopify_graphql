module ShopifyGraphql
  class AppSubscriptionFields
    FRAGMENT = <<~GRAPHQL
      fragment AppSubscriptionFields on AppSubscription {
        id
        name
        status
        createdAt
        trialDays
        currentPeriodEnd
        test
        lineItems {
          id
          plan {
            pricingDetails {
              __typename
              ... on AppRecurringPricing {
                price {
                  amount
                }
                interval
              }
              ... on AppUsagePricing {
                balanceUsed {
                  amount
                }
                cappedAmount {
                  amount
                }
                interval
                terms
              }
            }
          }
        }
      }
    GRAPHQL

    def self.parse(data)
      recurring_line_item = data.lineItems.find do |line_item|
        line_item.plan.pricingDetails.__typename == "AppRecurringPricing"
      end
      recurring_pricing = recurring_line_item&.plan&.pricingDetails
      usage_line_item = data.lineItems.find do |line_item|
        line_item.plan.pricingDetails.__typename == "AppUsagePricing"
      end
      usage_pricing = usage_line_item&.plan&.pricingDetails

      OpenStruct.new(
        id: data.id,
        name: data.name,
        status: data.status,
        created_at: data.createdAt && Time.parse(data.createdAt),
        trial_days: data.trialDays,
        current_period_end: data.currentPeriodEnd && Time.parse(data.currentPeriodEnd),
        test: data.test,
        recurring_line_item_id: recurring_line_item&.id,
        recurring_price: recurring_pricing&.price&.amount&.to_d,
        recurring_interval: recurring_pricing&.interval,
        usage_line_item_id: usage_line_item&.id,
        usage_balance: usage_pricing&.balanceUsed&.amount&.to_d,
        usage_capped_amount: usage_pricing&.cappedAmount&.amount&.to_d,
        usage_interval: usage_pricing&.interval,
        usage_terms: usage_pricing&.terms
      )
    end
  end
end
