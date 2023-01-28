require "test_helper"

class UpsertPrivateMetafieldTest < ActiveSupport::TestCase
  setup do
    @value = {foo: "baz"}
  end

  test "upserts shop metafield" do
    variables = {
      input: {
        namespace: "NAMESPACE",
        key: "KEY",
        valueInput: {
          value: @value.to_json,
          valueType: "JSON_STRING"
        }
      }
    }
    fake(
      "mutations/upsert_private_method_shop.json",
      ShopifyGraphql::UpsertPrivateMetafield::MUTATION,
      **variables
    )

    response = ShopifyGraphql::UpsertPrivateMetafield.call(
      namespace: "NAMESPACE",
      key: "KEY",
      value: @value
    ).data

    assert_equal "NAMESPACE", response.namespace
    assert_equal "KEY", response.key
    assert_equal @value.to_json, response.value
    assert_equal "JSON_STRING", response.value_type
  end

  test "upsert product metafield" do
    variables = {
      input: {
        namespace: "NAMESPACE",
        key: "KEY",
        owner: "gid://shopify/Product/6633850863839",
        valueInput: {
          value: @value.to_json,
          valueType: "JSON_STRING"
        }
      }
    }
    fake(
      "mutations/upsert_private_method_product.json",
      ShopifyGraphql::UpsertPrivateMetafield::MUTATION,
      **variables
    )

    response = ShopifyGraphql::UpsertPrivateMetafield.call(
      owner: "gid://shopify/Product/6633850863839",
      namespace: "NAMESPACE",
      key: "KEY",
      value: @value
    ).data

    assert_equal "NAMESPACE", response.namespace
    assert_equal "KEY", response.key
    assert_equal @value.to_json, response.value
    assert_equal "JSON_STRING", response.value_type
  end
end
