require "test_helper"

class ClientTest < ActiveSupport::TestCase
  QUERY = "query { shop { name } }"

  [ShopifyGraphql::Query, ShopifyGraphql::Mutation, ShopifyGraphql::Resource].each do |concern|
    test "#{concern} sends the rotated token after copying session attributes" do
      operation_class = Class.new { include concern }
      operation = concern == ShopifyGraphql::Resource ? operation_class : operation_class.new
      original = stub_query(API_PATH, "test-token")
      operation.execute(QUERY)

      new_session = ShopifyAPI::Auth::Session.new(shop: "test-shop.myshopify.com", access_token: "rotated-token")
      ShopifyAPI::Context.active_session.copy_attributes_from(new_session)

      rotated = stub_query(API_PATH, "rotated-token")
      operation.execute(QUERY)

      assert_requested original, times: 1
      assert_requested rotated, times: 1
    end
  end

  test "rebuilds the client when the shop changes with the same token" do
    client = ShopifyGraphql::Client.new
    original = stub_query(API_PATH, "test-token")
    client.execute(QUERY)

    ShopifyAPI::Context.activate_session(ShopifyAPI::Auth::Session.new(shop: "other-shop.myshopify.com", access_token: "test-token"))
    other = stub_query(API_PATH.sub("test-shop", "other-shop"), "test-token")
    client.execute(QUERY)

    assert_requested original, times: 1
    assert_requested other, times: 1
  end

  test "reuses the client when a replacement session has the same shop and token" do
    client = ShopifyGraphql::Client.new
    inner_client = client.client
    ShopifyAPI::Context.activate_session(ShopifyAPI::Auth::Session.new(shop: "test-shop.myshopify.com", access_token: "test-token"))

    assert_same inner_client, client.client
  end

  test "does not reuse an authenticated client after the session is deactivated" do
    client = ShopifyGraphql::Client.new
    client.client
    ShopifyAPI::Context.deactivate_session

    assert_raises(ShopifyAPI::Errors::NoActiveSessionError) { client.client }
  end

  private

  def stub_query(url, token)
    stub_request(:post, url)
      .with(body: { query: QUERY, variables: {} }, headers: { "X-Shopify-Access-Token" => token })
      .to_return(body: File.read(File.expand_path("fixtures/queries/shop.json", __dir__)))
  end
end
