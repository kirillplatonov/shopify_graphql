module ShopifyGraphql
  class Client
    RETRIABLE_EXCEPTIONS = [
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      'Timeout::Error',
      Faraday::TimeoutError,
      Faraday::RetriableResponse,
      Faraday::ParsingError,
      Faraday::ConnectionFailed,
    ].freeze

    def initialize(api_version = ShopifyAPI::Base.api_version)
      @api_version = api_version
    end

    def execute(query, **variables)
      operation_name = variables.delete(:operation_name)
      response = connection.post do |req|
        req.body = {
          query: query,
          operationName: operation_name,
          variables: variables,
        }.to_json
      end
      response = handle_response(response)
      ShopifyGraphql::Response.new(response)
    end

    def api_url
      [ShopifyAPI::Base.site, @api_version.construct_graphql_path].join
    end

    def request_headers
      ShopifyAPI::Base.headers
    end

    def connection
      @connection ||= Faraday.new(url: api_url, headers: request_headers) do |conn|
        conn.request :json
        conn.response :json, parser_options: { object_class: OpenStruct }
        conn.request :retry, max: 3, interval: 1, backoff_factor: 2, exceptions: RETRIABLE_EXCEPTIONS
      end
    end

    def handle_response(response)
      case response.status
      when 200..400
        handle_graphql_errors(response.body)
      when 400
        raise BadRequest.new(response.body, code: response.status)
      when 401
        raise UnauthorizedAccess.new(response.body, code: response.status)
      when 402
        raise PaymentRequired.new(response.body, code: response.status)
      when 403
        raise ForbiddenAccess.new(response.body, code: response.status)
      when 404
        raise ResourceNotFound.new(response.body, code: response.status)
      when 405
        raise MethodNotAllowed.new(response.body, code: response.status)
      when 409
        raise ResourceConflict.new(response.body, code: response.status)
      when 410
        raise ResourceGone.new(response.body, code: response.status)
      when 412
        raise PreconditionFailed.new(response.body, code: response.status)
      when 422
        raise ResourceInvalid.new(response.body, code: response.status)
      when 429
        raise TooManyRequests.new(response.body, code: response.status)
      when 401...500
        raise ClientError.new(response.body, code: response.status)
      when 500...600
        raise ServerError.new(response.body, code: response.status)
      else
        raise ConnectionError.new(response.body, "Unknown response code: #{response.status}")
      end
    end

    def handle_graphql_errors(response)
      return response if response.errors.blank?

      error = response.errors.first
      error_message = error.message
      error_code = error.extensions&.code
      error_doc = error.extensions&.documentation

      case error_code
      when "THROTTLED"
        raise TooManyRequests.new(response, error_message, code: error_code, doc: error_doc)
      else
        raise ConnectionError.new(response, error_message, code: error_code, doc: error_doc)
      end
    end

    def handle_user_errors(response)
      return response if response.userErrors.blank?

      error = response.userErrors.first
      error_message = error.message
      error_fields = error.field
      error_code = error.code

      raise UserError.new(response, error_message, fields: error_fields, code: error_code)
    end
  end

  class << self
    delegate :execute, :handle_user_errors, to: :client

    def client(api_version = ShopifyAPI::Base.api_version)
      Client.new(api_version)
    end
  end
end
