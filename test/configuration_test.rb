require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  setup do
    # Store the original configuration to restore it later
    @original_config = ShopifyGraphql.configuration.convert_case
  end

  teardown do
    # Restore original configuration
    ShopifyGraphql.configuration.convert_case = @original_config
  end

  test "convert_case defaults to false" do
    config = ShopifyGraphql::Configuration.new
    assert_equal false, config.convert_case
  end

  test "convert_case can be set to true" do
    ShopifyGraphql.configure do |config|
      config.convert_case = true
    end

    assert_equal true, ShopifyGraphql.configuration.convert_case
  end

  test "case conversion works with snake_case variables" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    query = "query($first_name: String!) { shop { name } }"
    variables = { first_name: "John" }

    fake("queries/shop.json", query, firstName: "John")

    client = ShopifyGraphql::Client.new
    response = client.execute(query, **variables)

    assert_equal "Graphql Gem Test", response.data.shop.name
  end

  test "response keys are converted to snake_case when enabled" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    query = "{ shop { name myshopifyDomain } }"
    fake("queries/shop.json", query)

    client = ShopifyGraphql::Client.new
    response = client.execute(query)

    # Response should have snake_case keys
    assert_equal "Graphql Gem Test", response.data.shop.name
    assert_equal "graphql-gem-test.myshopify.com", response.data.shop.myshopify_domain
  end

  test "original behavior when convert_case is disabled" do
    ShopifyGraphql.configure { |config| config.convert_case = false }

    query = "{ shop { name myshopifyDomain } }"
    fake("queries/shop.json", query)

    client = ShopifyGraphql::Client.new
    response = client.execute(query)

    # Response should maintain original camelCase keys
    assert_equal "Graphql Gem Test", response.data.shop.name
    assert_equal "graphql-gem-test.myshopify.com", response.data.shop.myshopifyDomain
  end
end