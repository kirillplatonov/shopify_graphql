module ShopifyGraphql
  class Configuration
    attr_accessor :webhooks
    attr_accessor :webhook_jobs_namespace
    attr_accessor :webhook_enabled_environments
    attr_accessor :webhooks_manager_queue_name
    attr_accessor :convert_case

    def initialize
      @webhooks_manager_queue_name = Rails.application.config.active_job.queue_name
      @webhook_enabled_environments = ['production']
      @convert_case = false
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
