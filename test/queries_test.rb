require "test_helper"

class QueriesTest < ActiveSupport::TestCase
  SIMPLE_QUERY = <<~GRAPHQL
    query {
      shop {
        id
        name
        myshopifyDomain
      }
    }
  GRAPHQL

  QUERY_WITH_VARIABLES = <<~GRAPHQL
    query($id: ID!) {
      product(id: $id) {
        title
        status
      }
    }
  GRAPHQL

  test "simple query" do
    fake("queries/shop.json", SIMPLE_QUERY)

    response = ShopifyGraphql.execute(SIMPLE_QUERY)
    shop = response.data.shop

    assert_equal "Graphql Gem Test", shop.name
  end

  test "query with params" do
    product_id = "gid://shopify/Product/6708081623123"
    fake("queries/product.json", QUERY_WITH_VARIABLES, id: product_id)

    response = ShopifyGraphql.execute(QUERY_WITH_VARIABLES, id: product_id)
    product = response.data.product

    assert_equal "Test product", product.title
    assert_equal "DRAFT", product.status
  end

  test "query with headers" do
    custom_headers = { "X-Custom-Header" => "test-value" }
    
    stub_request(:post, API_PATH)
      .with(
        body: { query: SIMPLE_QUERY, variables: {} },
        headers: custom_headers
      )
      .to_return(body: File.read(File.expand_path("fixtures/queries/shop.json", __dir__)))

    response = ShopifyGraphql.execute(SIMPLE_QUERY, headers: custom_headers)
    shop = response.data.shop

    assert_equal "Graphql Gem Test", shop.name
    assert_requested :post, API_PATH, headers: custom_headers
  end
end
