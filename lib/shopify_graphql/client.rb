module ShopifyGraphql
  # Mapping from deprecated plan_name to plan_display_name
  PLAN_TO_DISPLAY_NAME = {
    "trial" => "trial",
    "frozen" => "frozen",
    "fraudulent" => "cancelled",
    "shopify_alumni" =>	"shopify_alumni",
    "affiliate" => "development",
    "basic" => "basic",
    "professional" => "shopify",
    "npo_full" => "npo_full",
    "shopify_plus" => "shopify_plus",
    "staff" => "staff",
    "unlimited" => "advanced",
    "retail" => "retail",
    "cancelled" => "cancelled",
    "dormant" => "pause_and_build",
    "starter_2022" => "shopify_starter",
    "plus_partner_sandbox" => "shopify_plus_partner_sandbox",
    "paid_trial" => "extended_trial",
    "partner_test" => "developer_preview",
    "open_learning" => "open_learning",
    "staff_business" => "staff_business"
  }
  DISPLAY_NAME_TO_PLAN = PLAN_TO_DISPLAY_NAME.invert

  class Client
    NETWORK_ERRORS = [
      Errno::ECONNRESET,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::EPIPE,
      Errno::ENETUNREACH,
      Errno::EHOSTUNREACH,
      Errno::ETIMEDOUT,
      Net::ReadTimeout,
      Net::OpenTimeout,
      OpenSSL::SSL::SSLError,
      EOFError
    ].freeze

    def client
      session = ShopifyAPI::Context.active_session
      if @client.nil? || @access_token != session&.access_token || @shop != session&.shop
        @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
        @access_token = session.access_token&.dup
        @shop = session.shop.dup
      end
      @client
    end

    def execute(query, headers: nil, **variables)
      @last_response = nil
      response = client.query(query: query, variables: variables, headers: headers)
      @last_response = Response.new(handle_response(response))
    rescue ShopifyAPI::Errors::HttpResponseError => e
      @last_response = Response.new(handle_response(e.response, e))
    rescue JSON::ParserError => e
      raise ServerError.new(response: response), "Invalid JSON response: #{e.message}"
    rescue *NETWORK_ERRORS => e
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
      when 200...400
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
      errors = parsed_body.errors
      if errors.nil? || errors.empty?
        return parsed_body
      end

      unless errors.is_a?(Array) && errors.first.is_a?(OpenStruct)
        message = if errors.is_a?(OpenStruct)
          errors.to_h.map { |key, value| "#{key}: #{value}" }.join(", ")
        else
          Array(errors).join(", ")
        end
        exception = ConnectionError.new(response: response)
        exception.messages = [ message ]
        attach_graphql_response(exception, parsed_body)
        raise exception, generate_error_message(message: message)
      end

      error = errors.first
      error_code = error.extensions&.code
      error_message = generate_error_message(
        message: error.message,
        code: error_code,
        doc: error.extensions&.documentation
      )

      exception = case error_code
        when "THROTTLED"
          TooManyRequests.new(response: response)
        when "INTERNAL_SERVER_ERROR"
          ServerError.new(response: response)
        when "SHOP_PENDING_TERMINATION"
          ShopPendingTermination.new(response: response)
        else
          ConnectionError.new(response: response)
        end
      exception.error_code = error_code
      exception.error_codes = [ error_code ]
      exception.messages = [ error.message ]
      attach_graphql_response(exception, parsed_body)
      raise exception, error_message
    end

    def attach_graphql_response(exception, parsed_body)
      exception.data = parsed_body.data
      exception.errors = parsed_body.errors
      exception.graphql_response = Response.new(parsed_body)
    end

    # Pass the Response from execute as response: to attach its cost to UserError.
    # Without it, the last Response returned by execute on this client is used.
    def handle_user_errors(payload, response: nil)
      return payload if payload.userErrors.blank?

      error = payload.userErrors.first
      errors = payload.userErrors
      error_message = generate_user_errors_message(
        messages: errors.map(&:message),
        codes: errors.map(&:code),
        fields: errors.map(&:field),
      )

      exception = UserError.new(response: payload)
      exception.error_code = error.code
      exception.error_codes = errors.map(&:code)
      exception.fields = errors.map(&:field)
      exception.messages = errors.map(&:message)
      exception.data = payload
      exception.errors = errors
      exception.graphql_response = response || @last_response
      raise exception, error_message
    end

    def generate_error_message(message: nil, code: nil, doc: nil)
      string = "Failed.".dup
      string << " Response code = #{code}." if code
      string << " Response message = #{message}.".gsub("..", ".") if message
      string << " Documentation = #{doc}." if doc
      string
    end

    def generate_user_errors_message(messages: nil, codes: nil, fields: [])
      if fields.any?
        field_count = fields.size
        result = ["#{field_count} #{"field".pluralize(field_count)} have failed:"]
        
        fields.each.with_index do |field, index|
          field_details = ["\n-"]
          field_details << "Response code = #{codes[index]}." if codes&.at(index)
          field_details << "Response message = #{messages[index]}.".gsub("..", ".") if messages&.at(index)
          field_details << "Field = #{field}." if field

          result << field_details.join(" ")
        end
        
        result.join("\n")
      else
        result = ["Failed."]
        result << "Response code = #{codes.join(", ")}." if codes&.any?
        result << "Response message = #{messages&.join(", ")}.".gsub("..", ".") if messages&.any?
        
        result.join(" ")
      end
    end
  end

  class << self
    extend Forwardable
    def_delegators :client, :execute, :handle_user_errors

    def client
      Client.new
    end

    def normalize_plan_display_name(plan_display_name)
      return if plan_display_name.blank?
      plan_display_name.parameterize(separator: "_")
    end
  end
end
