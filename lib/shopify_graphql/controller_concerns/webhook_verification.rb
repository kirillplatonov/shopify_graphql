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
      ShopifyGraphql.deprecator.warn("ShopifyGraphql webhooks are deprecated and will be removed in v3.0. Please use shopify_app gem for handling webhooks.")
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
