module ShopifyGraphQL
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

  # 429 Too Many Requests
  class TooManyRequests < ClientError
  end

  # 5xx Server Error
  class ServerError < ConnectionError
  end
end
