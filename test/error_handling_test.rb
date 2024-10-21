require "test_helper"

class ErrorHandlingTest < ActiveSupport::TestCase
  SIMPLE_QUERY = <<~GRAPHQL
    query {
      shop {
        id
        name
        myshopifyDomain
      }
    }
  GRAPHQL

  test "handles invalid JSON response" do
    fake("error_page.html", SIMPLE_QUERY)

    assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end

  test "handles network error" do
    fake_error(Errno::ECONNRESET)

    assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end

  test "invalid input error" do
    fake("mutations/invalid_input_error.json", SIMPLE_QUERY)

    assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end

  test "user error" do
    fake("mutations/user_error.json", SIMPLE_QUERY)

    begin
      response = ShopifyGraphql.execute(SIMPLE_QUERY)
      ShopifyGraphql::Client.new.handle_user_errors(response.data.metafieldDefinitionCreate)
    rescue ShopifyGraphql::UserError => error
      assert_equal 200, error.code
      assert_equal "TAKEN", error.error_code
      assert_includes error.message, "Key is in use for Product metafields"
      assert_equal ["definition", "key"], error.fields
    end
  end

  test "server error" do
    fake("mutations/server_error.json", SIMPLE_QUERY)

    begin
      ShopifyGraphql.execute(SIMPLE_QUERY)
    rescue ShopifyGraphql::ServerError => error
      assert_equal 200, error.code
      assert_equal "INTERNAL_SERVER_ERROR", error.error_code
      assert_includes error.message, "Looks like something went wrong on our end"
    end
  end
end
