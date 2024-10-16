require "test_helper"

class CurrentShopTest < ActiveSupport::TestCase
  test "returns shop" do
    fake("queries/current_shop.json", ShopifyGraphql::CurrentShop::QUERY)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "Example Shop", shop.name
    assert_equal "user@example.com", shop.email
    assert_equal "example.myshopify.com", shop.myshopify_domain
  end

  test "returns shop with shop locales" do
    fake("queries/current_shop.json", ShopifyGraphql::CurrentShop::QUERY)

    shop = ShopifyGraphql::CurrentShop.call(with_locales: true)

    assert_equal "en", shop.primary_locale
    assert_equal ["da", "en", "es"], shop.shop_locales
  end

  test "plan normalization and fallback" do
    fake("queries/current_shop.json", ShopifyGraphql::CurrentShop::QUERY)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "developer_preview", shop.plan_display_name # normalized
    assert_equal "partner_test", shop.plan_name # mapped fallback
  end
end
