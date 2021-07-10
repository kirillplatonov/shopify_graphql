module ShopifyGraphql
  class CreateWebhooksJob < ActiveJob::Base
    queue_as do
      ShopifyGraphql.configuration.webhooks_manager_queue_name
    end

    def perform(shop_domain:, shop_token:)
      api_version = ShopifyApp.configuration.api_version
      webhooks = ShopifyGraphql.configuration.webhooks

      ShopifyAPI::Session.temp(domain: shop_domain, token: shop_token, api_version: api_version) do
        manager = WebhooksManager.new(webhooks)
        manager.create_webhooks
      end
    end
  end
end
