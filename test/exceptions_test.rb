require "test_helper"

class ExceptionsTest < ActiveSupport::TestCase
  SIMPLE_QUERY = <<~GRAPHQL
    query {
      shop {
        id
        name
        myshopifyDomain
      }
    }
  GRAPHQL

  test "JSON parse error" do
    fake("error_page.html", SIMPLE_QUERY)

    assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end
end
