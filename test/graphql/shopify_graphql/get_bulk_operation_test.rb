require "test_helper"

class GetBulkOperationTest < ActiveSupport::TestCase
  test "returns completed bulk operation" do
    id = "gid://shopify/BulkOperation/720918"
    fake("queries/bulk_operation_completed.json", ShopifyGraphql::GetBulkOperation::QUERY, id: id)

    bulk_operation = ShopifyGraphql::GetBulkOperation.call(id: id).data

    assert_equal id, bulk_operation.id
    assert_equal "QUERY", bulk_operation.type
    assert_equal "COMPLETED", bulk_operation.status
    assert_nil bulk_operation.error_code
    assert_equal Time.utc(2026, 10, 20, 10, 0, 0), bulk_operation.created_at
    assert_equal Time.utc(2026, 10, 20, 10, 2, 15), bulk_operation.completed_at
    assert_equal 4563987, bulk_operation.file_size
    assert_match %r{720918-final\.jsonl\z}, bulk_operation.url
    assert_nil bulk_operation.partial_data_url
    assert_equal 1500, bulk_operation.object_count
    assert_equal 500, bulk_operation.root_object_count
    assert_equal "{ products { edges { node { id variants { edges { node { id } } } } } } }", bulk_operation.query
  end

  test "returns failed bulk operation with partial data" do
    id = "gid://shopify/BulkOperation/720919"
    fake("queries/bulk_operation_failed.json", ShopifyGraphql::GetBulkOperation::QUERY, id: id)

    bulk_operation = ShopifyGraphql::GetBulkOperation.call(id: id).data

    assert_equal "FAILED", bulk_operation.status
    assert_equal "TIMEOUT", bulk_operation.error_code
    assert_nil bulk_operation.completed_at
    assert_nil bulk_operation.file_size
    assert_nil bulk_operation.url
    assert_match %r{720919-partial\.jsonl\z}, bulk_operation.partial_data_url
    assert_equal 250, bulk_operation.object_count
  end
end
