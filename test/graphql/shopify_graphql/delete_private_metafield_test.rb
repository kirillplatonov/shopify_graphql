require "test_helper"

class DeletePrivateMetafieldTest < ActiveSupport::TestCase
  test "deletes shop metafield" do
    variables = {
      input: {
        namespace: "NAMESPACE",
        key: "KEY"
      }
    }
    fake(
      "mutations/delete_private_method_shop.json",
      ShopifyGraphql::DeletePrivateMetafield::MUTATION,
      **variables
    )

    response = ShopifyGraphql::DeletePrivateMetafield.call(
      namespace: "NAMESPACE",
      key: "KEY"
    ).data

    assert_not_nil response.deleted_private_metafield_id
  end

  test "delete product metafield" do
    variables = {
      input: {
        namespace: "NAMESPACE",
        key: "KEY",
        owner: "gid://shopify/Product/6633850863839"
      }
    }
    fake(
      "mutations/delete_private_method_product.json",
      ShopifyGraphql::DeletePrivateMetafield::MUTATION,
      **variables
    )

    response = ShopifyGraphql::DeletePrivateMetafield.call(
      owner: "gid://shopify/Product/6633850863839",
      namespace: "NAMESPACE",
      key: "KEY"
    ).data

    assert_not_nil response.deleted_private_metafield_id
  end
end
