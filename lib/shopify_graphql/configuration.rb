module ShopifyGraphQL
  class Configuration
    attr_accessor :webhooks
    attr_accessor :webhook_jobs_namespace
    attr_accessor :webhook_enabled_environments
    attr_accessor :webhooks_manager_queue_name

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
