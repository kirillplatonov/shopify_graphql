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

      Struct
        .new(
          :id,
          :name,
          :status,
          :created_at,
          :trial_days,
          :current_period_end,
          :test,
          :recurring_line_item_id,
          :recurring_price,
          :recurring_interval,
          :usage_line_item_id,
          :usage_balance,
          :usage_capped_amount,
          :usage_interval,
          :usage_terms
        )
        .new(
          data.id,
          data.name,
          data.status,
          data.createdAt && Time.parse(data.createdAt),
          data.trialDays,
          data.currentPeriodEnd && Time.parse(data.currentPeriodEnd),
          data.test,
          recurring_line_item&.id,
          recurring_pricing&.price&.amount&.to_d,
          recurring_pricing&.interval,
          usage_line_item&.id,
          usage_pricing&.balanceUsed&.amount&.to_d,
          usage_pricing&.cappedAmount&.amount&.to_d,
          usage_pricing&.interval,
          usage_pricing&.terms
        )
    end
  end
end
