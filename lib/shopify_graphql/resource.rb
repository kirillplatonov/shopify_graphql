module ShopifyGraphql
  module Resource
    extend ActiveSupport::Concern

    # The gem's own Shop and Webhook warn when they're used instead
    INTERNAL_RESOURCES = %w[ShopifyGraphql::Shop ShopifyGraphql::Webhook].freeze
    private_constant :INTERNAL_RESOURCES

    included do
      unless INTERNAL_RESOURCES.include?(name)
        ShopifyGraphql::Deprecation.warn_once("ShopifyGraphql::Resource", "ShopifyGraphql::Resource is deprecated and will be removed in v3.0. " \
          "Please include ShopifyGraphql::Query or ShopifyGraphql::Mutation in your own classes instead.")
      end
    end

    class_methods do
      extend Forwardable
      def_delegators :client, :execute, :handle_user_errors

      def client
        ShopifyGraphql::Client.new
      end
    end
  end
end
