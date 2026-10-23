module ShopifyGraphql
  class GetBulkOperation
    include Query

    QUERY = <<~GRAPHQL
      query($id: ID!){
        node(id: $id) {
          ... on BulkOperation {
            id
            type
            status
            errorCode
            createdAt
            completedAt
            fileSize
            url
            partialDataUrl
            objectCount
            rootObjectCount
            query
          }
        }
      }
    GRAPHQL

    def call(id:)
      response = execute(QUERY, id: id)
      response.data = parse_data(response.data.node)
      response
    end

    private

    def parse_data(data)
      unless data
        raise ResourceNotFound.new, "BulkOperation not found"
      end

      OpenStruct.new(
        id: data.id,
        type: data.type,
        status: data.status,
        error_code: data.errorCode,
        created_at: Time.find_zone("UTC").parse(data.createdAt),
        completed_at: data.completedAt ? Time.find_zone("UTC").parse(data.completedAt) : nil,
        file_size: data.fileSize ? data.fileSize.to_i : nil,
        url: data.url,
        partial_data_url: data.partialDataUrl,
        object_count: data.objectCount.to_i,
        root_object_count: data.rootObjectCount.to_i,
        query: data.query,
      )
    end
  end
end
