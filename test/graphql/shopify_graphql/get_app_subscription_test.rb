require "test_helper"

class GetAppSubscriptionTest < ActiveSupport::TestCase
  test "returns subscription" do
    app_subscription_gid = "gid://shopify/AppSubscription/22229811283"
    fake("queries/app_subscription.json", ShopifyGraphql::GetAppSubscription::QUERY, id: app_subscription_gid)

    response = ShopifyGraphql::GetAppSubscription.call(id: app_subscription_gid)
    subscription = response.data

    assert_equal "Standard Plan", subscription.name
    assert_equal "PENDING", subscription.status
    assert_kind_of Time, subscription.created_at
    assert_equal 3, subscription.trial_days
    assert subscription.test
    assert_equal 29.99, subscription.recurring_price
    assert_equal "ANNUAL", subscription.recurring_interval
  end
end
