module ShopifyGraphql
  class ConnectionError < ShopifyAPI::Errors::HttpResponseError
    attr_accessor :error_code, :error_codes, :fields, :messages
    # Partial data from the GraphQL response. For UserError, the mutation payload.
    attr_accessor :data
    # GraphQL errors from the response, or an empty Array when there are none.
    # For UserError, the payload's userErrors.
    attr_writer :errors
    # ShopifyGraphql::Response the error came from, used for cost information
    attr_accessor :graphql_response

    def errors
      @errors || []
    end

    def query_cost
      graphql_response&.query_cost
    end

    def requested_query_cost
      graphql_response&.requested_query_cost
    end

    def points_left
      graphql_response&.points_left
    end

    def points_limit
      graphql_response&.points_limit
    end

    def points_restore_rate
      graphql_response&.points_restore_rate
    end

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

  # Marks errors that mean the shop can't be used right now: the app was
  # uninstalled or the token revoked, or the shop is frozen, locked, inactive or
  # pending termination. Use it to stop work for the shop:
  #
  #   rescue ShopifyGraphql::ShopUnavailable
  #   discard_on ShopifyGraphql::ShopUnavailable
  #
  # Members:
  # - UnauthorizedAccess (401): app uninstalled or access token revoked. Shopify
  #   also returns 401 for an expired access token, so with expiring offline
  #   tokens a 401 can mean the token wasn't refreshed. Refresh it before
  #   treating the shop as gone.
  # - PaymentRequired (402): shop is frozen
  # - ShopLocked (423): shop is locked
  # - ShopPendingTermination (SHOP_PENDING_TERMINATION): shop is under review
  # - ShopInactive (SHOP_INACTIVE): shop is not active
  #
  # Not included:
  # - ForbiddenAccess (403) and NonExpiringTokenRejected. On GraphQL, a 403 means
  #   the shop was marked as fraudulent, and from January 1, 2027 it's also
  #   returned for a non-expiring offline access token. Treating every 403 as
  #   "shop gone" could mark every shop uninstalled once those tokens stop working.
  # - ResourceNotFound (404). It's also raised for null nodes.
  # - AccessDenied (ACCESS_DENIED). It means a missing access scope.
  module ShopUnavailable
  end

  # 4xx Client Error
  class ClientError < ConnectionError
  end

  # 400 Bad Request
  class BadRequest < ClientError # :nodoc:
  end

  # 401 Unauthorized
  class UnauthorizedAccess < ClientError # :nodoc:
    include ShopUnavailable
  end

  # 402 Payment Required
  class PaymentRequired < ClientError # :nodoc:
    include ShopUnavailable
  end

  # 403 Forbidden
  class ForbiddenAccess < ClientError # :nodoc:
  end

  # 403 Forbidden for a public app's non-expiring offline access token, returned
  # from January 1, 2027. Exchange it for an expiring token.
  class NonExpiringTokenRejected < ForbiddenAccess # :nodoc:
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
    include ShopUnavailable
  end

  # GraphQL SHOP_PENDING_TERMINATION error code (shop is under review)
  class ShopPendingTermination < ClientError # :nodoc:
    include ShopUnavailable
  end

  # GraphQL SHOP_INACTIVE error code (shop is not active, e.g. after repeated
  # rate limit overages or due to fraud risk)
  class ShopInactive < ClientError # :nodoc:
    include ShopUnavailable
  end

  # GraphQL ACCESS_DENIED error code (missing access scope). Returned with
  # HTTP 200, not 403.
  class AccessDenied < ClientError # :nodoc:
  end

  # GraphQL MAX_COST_EXCEEDED error code (query is over the single query cost
  # limit). Retrying doesn't help: reduce the query or use a bulk operation.
  class MaxCostExceeded < ClientError # :nodoc:
  end

  # 429 Too Many Requests
  class TooManyRequests < ClientError # :nodoc:
  end

  # 5xx Server Error
  class ServerError < ConnectionError
  end

  # Custom error for Graphql userErrors handling
  class UserError < ConnectionError
  end
end
