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
    assert_equal 2000, shop.graphql_points_limit
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

  test "returns plan details" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "Developer Preview", shop.plan_public_display_name
    assert_equal false, shop.plan_shopify_plus
    assert_equal true, shop.plan_partner_development
  end

  test "returns shop address" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "United States", shop.country_name
    assert_equal "US", shop.country
    assert_equal "US", shop.country_code
    assert_equal "New York", shop.province
    assert_equal "NY", shop.province_code
    assert_equal "", shop.address2
    assert_nil shop.city
  end

  test "returns fields that are always queried" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call

    assert_equal "Example User", shop.shop_owner
    assert_equal "2023-02-18T08:52:34Z", shop.created_at
    assert_equal "2024-10-16T09:02:20Z", shop.updated_at
    assert_equal false, shop.marketing_sms_consent_enabled_at_checkout
    assert_equal true, shop.unified_markets
    assert_equal "gid://shopify/AppInstallation/456", shop.app_installation_id
    assert_equal true, shop.password_enabled
  end

  test "does not query products count by default" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call

    assert_not_includes query, "productsCount"
    assert_requested :post, API_PATH, body: { query: query, variables: {} }
    assert_nil shop.products_count
  end

  test "returns products count" do
    query = ShopifyGraphql::CurrentShop.new.send(:prepare_query, ShopifyGraphql::CurrentShop::QUERY, with_locales: false, with_products_count: true)
    fake("queries/current_shop.json", query)

    shop = ShopifyGraphql::CurrentShop.call(with_products_count: true)

    assert_includes query, "productsCount"
    assert_requested :post, API_PATH, body: { query: query, variables: {} }
    assert_equal 42, shop.products_count
  end
end
