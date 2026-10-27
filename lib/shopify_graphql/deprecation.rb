require 'set'

module ShopifyGraphql
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("3.0", "ShopifyGraphql")
  end

  # Warnings for APIs removed in v3.0. Webhook jobs and managers run for every
  # shop, so each API warns once per process instead of on every call.
  module Deprecation # :nodoc:
    PLAN_MESSAGE = "Please use plan_public_display_name, plan_shopify_plus and plan_partner_development from ShopifyGraphql::CurrentShop instead."
    # Skipped in "called from" so the warning points at the app's code
    GEM_PATHS = [File.expand_path("..", __dir__), File.expand_path("../../app", __dir__)].map { |path| "#{path}/" }.freeze

    @warned = Set.new
    @mutex = Mutex.new

    class << self
      def warn_once(key, message)
        return unless @mutex.synchronize { @warned.add?(key) }
        callstack = caller_locations.drop_while { |frame| frame.absolute_path.to_s.start_with?(*GEM_PATHS) }
        ShopifyGraphql.deprecator.warn(message, callstack)
      end

      def warn_webhooks_once(api)
        warn_once(api, "#{api} is part of ShopifyGraphql webhooks, which are deprecated and will be removed in v3.0. " \
          "Please use shopify_app gem for handling webhooks or declare webhook subscriptions in shopify.app.toml.")
      end

      # Used by tests to see warnings again
      def reset
        @mutex.synchronize { @warned.clear }
      end
    end
  end

  def self.const_missing(name)
    return super unless %i[PLAN_TO_DISPLAY_NAME DISPLAY_NAME_TO_PLAN].include?(name)

    Deprecation.warn_once("ShopifyGraphql::#{name}", "ShopifyGraphql::#{name} is deprecated and will be removed in v3.0. #{Deprecation::PLAN_MESSAGE}")
    PlanNames.const_get(name)
  end

  def self.normalize_plan_display_name(plan_display_name)
    Deprecation.warn_once("ShopifyGraphql.normalize_plan_display_name", "ShopifyGraphql.normalize_plan_display_name is deprecated and will be removed in v3.0. #{Deprecation::PLAN_MESSAGE}")
    PlanNames.normalize_display_name(plan_display_name)
  end
end
