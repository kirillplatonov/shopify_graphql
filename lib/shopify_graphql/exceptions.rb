module ShopifyGraphql
  class ConnectionError < ShopifyAPI::Errors::HttpResponseError
    def initialize(response: nil)
      unless response
        empty_response = ShopifyAPI::Clients::HttpResponse.new(code: 200, headers: {}, body: "")
        super(response: empty_response) and return
      end

      if response.is_a?(ShopifyAPI::Clients::HttpResponse)
        super(response: response)
      else
        response = ShopifyAPI::Clients::HttpResponse.new(
          code: 200,
          headers: {},
          body: response
        )
        super(response: response)
      end
    end
  end

  # 4xx Client Error
  class ClientError < ConnectionError
  end

  # 400 Bad Request
  class BadRequest < ClientError # :nodoc:
  end

  # 401 Unauthorized
  class UnauthorizedAccess < ClientError # :nodoc:
  end

  # 402 Payment Required
  class PaymentRequired < ClientError # :nodoc:
  end

  # 403 Forbidden
  class ForbiddenAccess < ClientError # :nodoc:
  end

  # 404 Not Found
  class ResourceNotFound < ClientError # :nodoc:
  end

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:
  end

  # 409 Conflict
  class ResourceConflict < ClientError # :nodoc:
  end

  # 410 Gone
  class ResourceGone < ClientError # :nodoc:
  end

  # 412 Precondition Failed
  class PreconditionFailed < ClientError # :nodoc:
  end

  # 423 Locked
  class ShopLocked < ClientError # :nodoc:
  end

  # 429 Too Many Requests
  class TooManyRequests < ClientError # :nodoc:
  end

  # Graphql userErrors
  class UserError < ClientError # :nodoc:
  end

  # 5xx Server Error
  class ServerError < ConnectionError
  end
end
