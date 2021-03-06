module ShopifyGraphql
  class MissingWebhookJobError < StandardError; end

  class GraphqlWebhooksController < ActionController::Base
    include ShopifyGraphql::WebhookVerification

    def receive
      params.permit!
      webhook_job_klass.perform_later(shop_domain: shop_domain, webhook: webhook_params.to_h)
      head(:ok)
    end

    private

    def webhook_params
      params.except(:controller, :action, :type)
    end

    def webhook_job_klass
      webhook_job_klass_name.safe_constantize || raise(ShopifyGraphql::MissingWebhookJobError)
    end

    def webhook_job_klass_name(type = webhook_type)
      [webhook_namespace, "#{type}_job"].compact.join('/').classify
    end

    def webhook_type
      params[:type]
    end

    def webhook_namespace
      ShopifyGraphql.configuration.webhook_jobs_namespace
    end
  end
end
