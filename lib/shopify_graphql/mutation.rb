module ShopifyGraphql::Mutation
  extend ActiveSupport::Concern

  class_methods do
    def call(**kwargs, &block)
      new.call(**kwargs, &block)
    end
  end

  extend Forwardable
  def_delegators :client, :execute, :handle_user_errors

  def client
    @client ||= ShopifyGraphql::Client.new
  end
end
