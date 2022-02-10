module ShopifyGraphql
  module RedactJobParams
    private

    def args_info(job)
      log_disabled_classes = %[
        ShopifyGraphql::CreateWebhooksJob
        ShopifyGraphql::DestroyWebhooksJob
        ShopifyGraphql::UpdateWebhooksJob
      ]
      return "" if log_disabled_classes.include?(job.class.name)
      super
    end
  end

  class Engine < ::Rails::Engine
    engine_name 'shopify_graphql'
    isolate_namespace ShopifyGraphql

    initializer "shopify_graphql.redact_job_params" do
      ActiveSupport.on_load(:active_job) do
        if ActiveJob::Base.respond_to?(:log_arguments?)
          CreateWebhooksJob.log_arguments = false
          DestroyWebhooksJob.log_arguments = false
          UpdateWebhooksJob.log_arguments = false
        elsif ActiveJob::Logging::LogSubscriber.private_method_defined?(:args_info)
          ActiveJob::Logging::LogSubscriber.prepend(RedactJobParams)
        end
      end
    end
  end
end
