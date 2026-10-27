module ShopifyGraphql
  class Configuration
    attr_reader :webhooks
    attr_reader :webhook_jobs_namespace
    attr_accessor :webhook_enabled_environments
    attr_accessor :webhooks_manager_queue_name

    def initialize
      @webhooks_manager_queue_name = Rails.application.config.active_job.queue_name
      @webhook_enabled_environments = ['production']
    end

    def webhooks=(webhooks)
      ShopifyGraphql::Deprecation.warn_webhooks_once("ShopifyGraphql::Configuration#webhooks=") if webhooks.present?
      @webhooks = webhooks
    end

    def webhook_jobs_namespace=(namespace)
      ShopifyGraphql::Deprecation.warn_webhooks_once("ShopifyGraphql::Configuration#webhook_jobs_namespace=") if namespace.present?
      @webhook_jobs_namespace = namespace
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
