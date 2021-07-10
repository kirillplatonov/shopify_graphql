module ShopifyGraphql
  class ConnectionError < StandardError
    attr_reader :response

    def initialize(response, message = nil, code: nil, doc: nil, fields: nil)
      @response = response
      @message = message
      @code = code
      @doc = doc
      @fields = fields
    end

    def to_s
      message = "Failed.".dup
      message << " Response code = #{@code}." if @code
      message << " Response message = #{@message}." if @message
      message << " Documentation = #{@doc}." if @doc
      message << " Fields = #{@fields}." if @fields
      message
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

   # 429 Too Many Requests
   class TooManyRequests < ClientError # :nodoc:
   end

  # 5xx Server Error
  class ServerError < ConnectionError
  end
end
