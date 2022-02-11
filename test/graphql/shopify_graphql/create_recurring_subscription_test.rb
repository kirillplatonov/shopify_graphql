require "test_helper"

class CreateRecurringSubscriptionTest < ActiveSupport::TestCase
  test "creates subscription" do
    variables = {
      name: "Standard Plan",
      returnUrl: "https://example.com/returnUrl",
      lineItems: [{
        plan: {
          appRecurringPricingDetails: {
            price: { amount: 29.99, currencyCode: "USD" },
            interval: "ANNUAL"
          }
        }
      }],
      trialDays: 3,
      test: true
    }
    fake(
      "mutations/create_recurring_subscription.json",
      ShopifyGraphql::CreateRecurringSubscription::MUTATION,
      **variables
    )

    response = ShopifyGraphql::CreateRecurringSubscription.call(
      name: "Standard Plan",
      price: 29.99,
      return_url: "https://example.com/returnUrl",
      trial_days: 3,
      test: true,
      interval: :annual
    )
    subscription = response.data.subscription

    assert_not_nil subscription.id
    assert_equal "Standard Plan", subscription.name
    assert_equal "PENDING", subscription.status
    assert_kind_of Time, subscription.created_at
    assert_equal 3, subscription.trial_days
    assert subscription.test
    assert_equal 29.99, subscription.recurring_price
    assert_equal "ANNUAL", subscription.recurring_interval
    assert_match %r{/admin/charges/(\d+)/(\d+)/RecurringApplicationCharge/confirm_recurring_application_charge}, response.data.confirmation_url
  end
end
