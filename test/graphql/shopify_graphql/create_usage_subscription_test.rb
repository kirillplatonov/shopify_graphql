require "test_helper"

class CreateUsageSubscriptionTest < ActiveSupport::TestCase
  test "creates subscription" do
    variables = {
      name: "Standard Plan",
      returnUrl: "https://example.com/returnUrl",
      test: true,
      lineItems: [{
        plan: {
          appUsagePricingDetails: {
            terms: "Terms Description",
            cappedAmount: {amount: 50, currencyCode: "USD"}
          }
        }
      }]
    }
    fake(
      "mutations/create_usage_subscription.json",
      ShopifyGraphql::CreateUsageSubscription::MUTATION,
      **variables
    )

    response = ShopifyGraphql::CreateUsageSubscription.call(
      name: "Standard Plan",
      return_url: "https://example.com/returnUrl",
      test: true,
      terms: "Terms Description",
      capped_amount: 50
    )
    subscription = response.data.subscription

    assert_not_nil subscription.id
    assert_equal "Standard Plan", subscription.name
    assert_equal "PENDING", subscription.status
    assert_equal 0, subscription.trial_days
    assert_nil subscription.current_period_end
    assert subscription.test
    assert_equal 0.0, subscription.usage_balance
    assert_equal 50.0, subscription.usage_capped_amount
    assert_equal "EVERY_30_DAYS", subscription.usage_interval
    assert_equal "Terms Description", subscription.usage_terms
    assert_match %r{/admin/charges/(\d+)/(\d+)/RecurringApplicationCharge/confirm_recurring_application_charge}, response.data.confirmation_url
  end
end
