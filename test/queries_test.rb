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
end
