module ShopifyGraphql
  module WebhookVerification
    extend ActiveSupport::Concern
    include ShopifyGraphql::PayloadVerification

    included do
      before_action :deprecate_webhooks
      skip_before_action :verify_authenticity_token, raise: false
      before_action :verify_request
    end

    private

    def deprecate_webhooks
      ShopifyGraphql::Deprecation.warn_webhooks_once("ShopifyGraphql::WebhookVerification")
    rescue ActiveSupport::DeprecationException => e
      # Failing the request would make Shopify retry and eventually drop the subscription
      logger&.warn(e.message)
    end

    def verify_request
      data = request.raw_post
      return head(:unauthorized) unless hmac_valid?(data)
    end

    def shop_domain
      request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
    end
  end
end
