require "test_helper"

class ResponseTest < ActiveSupport::TestCase
  QUERY = "query { shop { name } }"

  test "points_maxed? compares points left with threshold" do
    fake("queries/shop.json", QUERY)

    response = ShopifyGraphql::Client.new.execute(QUERY)

    assert_equal 999, response.points_left
    refute response.points_maxed?
    refute response.points_maxed?(threshold: 999)
    assert response.points_maxed?(threshold: 1000)
  end

  test "points_maxed? is false when response has no cost data" do
    stub_request(:post, API_PATH).to_return(body: { data: { shop: { name: "Test" } } }.to_json)

    response = ShopifyGraphql::Client.new.execute(QUERY)

    assert_nil response.points_left
    refute response.points_maxed?
    refute response.points_maxed?(threshold: 100)
  end
end
