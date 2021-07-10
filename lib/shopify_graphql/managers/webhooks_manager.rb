module ShopifyGraphQL
  class WebhooksManager
    class << self
      def queue_create(shop_domain, shop_token, webhooks)
        ShopifyGraphQL::CreateWebhooksJob.perform_later(
          shop_domain: shop_domain,
          shop_token: shop_token,
        )
      end

      def queue_destroy(shop_domain, shop_token, webhooks)
        ShopifyGraphQL::DestroyWebhooksJob.perform_later(
          shop_domain: shop_domain,
          shop_token: shop_token,
        )
      end

      def queue_update(shop_domain, shop_token, webhooks)
        ShopifyGraphQL::UpdateWebhooksJob.perform_later(
          shop_domain: shop_domain,
          shop_token: shop_token,
        )
      end
    end

    attr_reader :required_webhooks

    def initialize(webhooks)
      @required_webhooks = webhooks
    end

    def recreate_webhooks!
      destroy_webhooks
      create_webhooks
    end

    def create_webhooks
      return unless webhooks_enabled?
      return unless required_webhooks.present?

      required_webhooks.each do |webhook|
        create_webhook(webhook) unless webhook_exists?(webhook[:topic])
      end
    end

    def destroy_webhooks
      return unless webhooks_enabled?

      current_webhooks.each do |webhook|
        ShopifyGraphQL::Webhook.delete(webhook.id) if required_webhook?(webhook)
      end

      @current_webhooks = nil
    end

    private

    def webhooks_enabled?
      if ShopifyGraphQL.configuration.webhook_enabled_environments.include?(Rails.env)
        true
      else
        Rails.logger.info("[ShopifyGraphQL] Webhooks disabled in #{Rails.env} environment. Check you config.")
        false
      end
    end

    def required_webhook?(webhook)
      webhook_address = webhook.endpoint.callbackUrl
      required_webhooks.any? { |w| w[:address] == webhook_address }
    end

    def create_webhook(attributes)
      ShopifyGraphQL::Webhook.create(
        topic: attributes[:topic],
        address: attributes[:address],
        include_fields: attributes[:include_fields],
      )
    end

    def webhook_exists?(topic)
      current_webhooks.any? do |webhook|
        webhook.topic == topic
      end
    end

    def current_webhooks
      @current_webhooks ||= ShopifyGraphQL::Webhook.all
    end
  end
end
