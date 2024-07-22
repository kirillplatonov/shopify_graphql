module ShopifyGraphql
  class Client
    def client
      @client ||= ShopifyAPI::Clients::Graphql::Admin.new(session: ShopifyAPI::Context.active_session)
    end

    def execute(query, **variables)
      response = client.query(query: query, variables: variables)
      Response.new(handle_response(response))
    rescue ShopifyAPI::Errors::HttpResponseError => e
      Response.new(handle_response(e.response))
    rescue JSON::ParserError => e
      raise ServerError.new(e, "Invalid JSON response")
    rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ECONNREFUSED, Errno::ENETUNREACH, Net::ReadTimeout, Net::OpenTimeout, OpenSSL::SSL::SSLError, EOFError => e
      raise ServerError.new(e, "Network error")
    rescue => e
      if (defined?(Socket::ResolutionError) and e.is_a?(Socket::ResolutionError))
        raise ServerError.new(response: response), "Network error: #{e.message}"
      else
        raise e
      end
    end

    def parsed_body(response)
      if response.body.is_a?(Hash)
        JSON.parse(response.body.to_json, object_class: OpenStruct)
      else
        response.body
      end
    end

    def handle_response(response)
      case response.code
      when 200..400
        handle_graphql_errors(parsed_body(response))
      when 400
        raise BadRequest.new(parsed_body(response), code: response.code)
      when 401
        raise UnauthorizedAccess.new(parsed_body(response), code: response.code)
      when 402
        raise PaymentRequired.new(parsed_body(response), code: response.code)
      when 403
        raise ForbiddenAccess.new(parsed_body(response), code: response.code)
      when 404
        raise ResourceNotFound.new(parsed_body(response), code: response.code)
      when 405
        raise MethodNotAllowed.new(parsed_body(response), code: response.code)
      when 409
        raise ResourceConflict.new(parsed_body(response), code: response.code)
      when 410
        raise ResourceGone.new(parsed_body(response), code: response.code)
      when 412
        raise PreconditionFailed.new(parsed_body(response), code: response.code)
      when 422
        raise ResourceInvalid.new(parsed_body(response), code: response.code)
      when 423
        raise ShopLocked.new(parsed_body(response), code: response.code)
      when 429, 430
        raise TooManyRequests.new(parsed_body(response), code: response.code)
      when 401...500
        raise ClientError.new(parsed_body(response), code: response.code)
      when 500...600
        raise ServerError.new(parsed_body(response), code: response.code)
      else
        raise ConnectionError.new(parsed_body(response), "Unknown response code: #{response.code}")
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
      when "INTERNAL_SERVER_ERROR"
        raise ServerError.new(response, error_message, code: error_code, doc: error_doc)
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

    def client
      Client.new
    end
  end
end
