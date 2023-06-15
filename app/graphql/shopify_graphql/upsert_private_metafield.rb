module ShopifyGraphql
  class UpsertPrivateMetafield
    include ShopifyGraphql::Mutation

    MUTATION = <<~GRAPHQL
      mutation privateMetafieldUpsert($input: PrivateMetafieldInput!) {
        privateMetafieldUpsert(input: $input) {
          privateMetafield {
            id
            namespace
            key
            value
            valueType
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def call(namespace:, key:, value:, owner: nil)
      input = {namespace: namespace, key: key}
      input[:owner] = owner if owner

      case value
      when Hash, Array
        value = value.to_json
        value_type = "JSON_STRING"
      when Integer
        value_type = "INTEGER"
      else
        value = value.to_s
        value_type = "STRING"
      end
      input[:valueInput] = {value: value, valueType: value_type}

      response = execute(MUTATION, input: input)
      handle_user_errors(response.data.privateMetafieldUpsert)
      response.data = parse_data(response.data)
      response
    end

    private

    def parse_data(data)
      metafield = data.privateMetafieldUpsert.privateMetafield
      Struct
        .new(
          :id,
          :namespace,
          :key,
          :value,
          :value_type
        )
        .new(
          metafield.id,
          metafield.namespace,
          metafield.key,
          metafield.value,
          metafield.valueType
        )
    end
  end
end
