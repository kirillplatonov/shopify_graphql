module ShopifyGraphql
  class CreateWebhooksJob < ActiveJob::Base
    queue_as do
      ShopifyGraphql.configuration.webhooks_manager_queue_name
    end

    def perform(shop_domain:, shop_token:)
      webhooks = ShopifyGraphql.configuration.webhooks

      ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do
        manager = WebhooksManager.new(webhooks)
        manager.create_webhooks
      end
    rescue UnauthorizedAccess, ResourceNotFound, ForbiddenAccess, PaymentRequired
      # Ignore
    end
  end
end
