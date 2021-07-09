module ShopifyGraphQL
  class Client
    attr_accessor :api_version, :gqli_client

    delegate :execute, :execute!, to: :gqli_client

    def initialize(api_version = ShopifyAPI::Base.api_version)
      self.api_version = api_version
      self.gqli_client = initialize_gqli_client
    end

    private

    def initialize_gqli_client
      GQLi::Client.new(
        graphql_api_url,
        headers: request_headers,
        validate_query: false,
      )
    end

    def graphql_api_url
      [ShopifyAPI::Base.site, api_version.construct_graphql_path].join
    end

    def request_headers
      ShopifyAPI::Base.headers.each_with_object({}) do |(key, value), new_hash|
        new_hash[key.underscore.to_sym] = value
      end
    end
  end

  def self.client(api_version = ShopifyAPI::Base.api_version)
    Client.new(api_version)
  end
end
