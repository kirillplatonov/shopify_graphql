require "test_helper"

class MutationsTest < ActiveSupport::TestCase
  SIMPLE_MUTATION = <<~GRAPHQL
    mutation($product_id: ID!, $new_title: String!) {
      productDuplicate(productId: $product_id, newTitle: $new_title) {
        newProduct {
          id
          title
        }
      }
    }
  GRAPHQL

  test "simple mutation" do
    fake("mutations/duplicate_product.json", SIMPLE_MUTATION)

    response = ShopifyGraphql.execute(SIMPLE_MUTATION)
    product = response.data.productDuplicate.newProduct
    assert_equal "gid://shopify/Product/6708088832083", product.id
    assert_equal "Test product duplicate", product.title
  end
end
