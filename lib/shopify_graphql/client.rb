module ShopifyGraphql
  class Client
    def client
      @client ||= ShopifyAPI::Clients::Graphql::Admin.new(session: ShopifyAPI::Context.active_session)
    end

    def execute(query, **variables)
      response = client.query(query: query, variables: variables)
      Response.new(handle_response(response))
    rescue ShopifyAPI::Errors::HttpResponseError => e
      Response.new(handle_response(e.response, e))
    rescue JSON::ParserError => e
      raise ServerError.new(response: response), "Invalid JSON response: #{e.message}"
    rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ECONNREFUSED, Errno::ENETUNREACH, Net::ReadTimeout, Net::OpenTimeout, OpenSSL::SSL::SSLError, EOFError => e
      raise ServerError.new(response: response), "Network error: #{e.message}"
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

    def handle_response(response, error = nil)
      case response.code
      when 200..400
        handle_graphql_errors(response)
      when 400
        raise BadRequest.new(response: response), error.message
      when 401
        raise UnauthorizedAccess.new(response: response), error.message
      when 402
        raise PaymentRequired.new(response: response), error.message
      when 403
        raise ForbiddenAccess.new(response: response), error.message
      when 404
        raise ResourceNotFound.new(response: response), error.message
      when 405
        raise MethodNotAllowed.new(response: response), error.message
      when 409
        raise ResourceConflict.new(response: response), error.message
      when 410
        raise ResourceGone.new(response: response), error.message
      when 412
        raise PreconditionFailed.new(response: response), error.message
      when 422
        raise ResourceInvalid.new(response: response), error.message
      when 423
        raise ShopLocked.new(response: response), error.message
      when 429, 430
        raise TooManyRequests.new(response: response), error.message
      when 401...500
        raise ClientError.new(response: response), error.message
      when 500...600
        raise ServerError.new(response: response), error.message
      else
        raise ConnectionError.new(response: response), error.message
      end
    end

    def handle_graphql_errors(response)
      parsed_body = parsed_body(response)
      if parsed_body.errors.nil? || parsed_body.errors.empty?
        return parsed_body(response)
      end

      error = parsed_body.errors.first
      error_code = error.extensions&.code
      error_message = generate_error_message(
        message: error.message,
        code: error_code,
        doc: error.extensions&.documentation
      )

      case error_code
      when "THROTTLED"
        raise TooManyRequests.new(response: response), error_message
      when "INTERNAL_SERVER_ERROR"
        raise ServerError.new(response: response), error_message
      else
        raise ConnectionError.new(response: response), error_message
      end
    end

    def handle_user_errors(response)
      return response if response.userErrors.blank?

      error = response.userErrors.first
      error_message = generate_error_message(
        message: error.message,
        code: error.code,
        fields: error.field,
      )
      raise UserError.new(
        response: response,
        message: error.message,
        code: error.code,
        fields: error.field,
      ), error_message
    end

    def generate_error_message(message: nil, code: nil, doc: nil, fields: nil)
      string = "Failed.".dup
      string << " Response code = #{code}." if code
      string << " Response message = #{message}.".gsub("..", ".") if message
      string << " Documentation = #{doc}." if doc
      string << " Fields = #{fields}." if fields
      string
    end
  end

  class << self
    extend Forwardable
    def_delegators :client, :execute, :handle_user_errors

    def client
      Client.new
    end
  end
end
