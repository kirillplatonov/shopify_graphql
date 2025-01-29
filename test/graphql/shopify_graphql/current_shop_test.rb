require "test_helper"

class CurrentShopTest < ActiveSupport::TestCase
  test "returns shop" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "Example Shop", shop.name
    assert_equal "user@example.com", shop.email
    assert_equal "example.myshopify.com", shop.myshopify_domain
    assert_equal 3, shop.max_product_options
    assert_equal 100, shop.max_product_variants
  end

  test "returns shop with shop locales" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: true)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call(with_locales: true)

    assert_equal "en", shop.primary_locale
    assert_equal ["da", "en", "es"], shop.shop_locales
  end

  test "plan normalization and fallback" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "developer_preview", shop.plan_display_name # normalized
    assert_equal "partner_test", shop.plan_name # mapped fallback
  end
end
