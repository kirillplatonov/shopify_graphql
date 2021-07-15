module ShopifyGraphQL
  class Webhook
    include Resource

    ALL_WEBHOOKS_QUERY = <<~GRAPHQL
      query {
        webhookSubscriptions(first: 250) {
          edges {
            node {
              id
              topic
              endpoint {
                ... on WebhookHttpEndpoint {
                  callbackUrl
                }
              }
            }
          }
        }
      }
    GRAPHQL

    CREATE_WEBHOOK_MUTATION = <<~GRAPHQL
      mutation($topic: WebhookSubscriptionTopic!, $webhookSubscription: WebhookSubscriptionInput!) {
        webhookSubscriptionCreate(topic: $topic, webhookSubscription: $webhookSubscription) {
          webhookSubscription {
            id
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    DELETE_WEBHOOK_MUTATION = <<~GRAPHQL
      mutation($id: ID!) {
        webhookSubscriptionDelete(id: $id) {
          deletedWebhookSubscriptionId
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    class << self
      def all
        response = execute(ALL_WEBHOOKS_QUERY)
        response.data.webhookSubscriptions.edges.map do |edge|
          edge.node
        end
      end

      def create(topic:, address:, include_fields:)
        response = execute(CREATE_WEBHOOK_MUTATION, variables: {
          topic: topic,
          webhookSubscription: {
            callbackUrl: address,
            format: 'JSON',
            includeFields: include_fields,
          },
        })
        response = response.data.webhookSubscriptionCreate
        handle_user_errors(response)
      end

      def delete(id)
        response = execute(DELETE_WEBHOOK_MUTATION, variables: { id: id })
        response = response.data.webhookSubscriptionDelete
        handle_user_errors(response)
      end
    end
  end
end
