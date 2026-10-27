module ShopifyGraphql
  class Configuration
    # All settings configure the deprecated webhooks
    %i[webhooks webhook_jobs_namespace webhook_enabled_environments webhooks_manager_queue_name].each do |setting|
      attr_reader setting

      define_method(:"#{setting}=") do |value|
        ShopifyGraphql::Deprecation.warn_webhooks_once("ShopifyGraphql::Configuration##{setting}=") if value.present?
        instance_variable_set(:"@#{setting}", value)
      end
    end

    def initialize
      @webhooks_manager_queue_name = Rails.application.config.active_job.queue_name
      @webhook_enabled_environments = ['production']
    end

    def has_webhooks?
      webhooks.present?
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end
end
