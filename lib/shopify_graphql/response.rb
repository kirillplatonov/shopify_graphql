module ShopifyGraphql
  class Response
    attr_reader :raw, :extensions, :errors
    attr_accessor :data

    def initialize(response)
      @raw = response
      @data = response.data
      @extensions = response.extensions
      @errors = response.errors
    end

    def points_left
      extensions&.cost&.throttleStatus&.currentlyAvailable
    end

    def points_limit
      extensions&.cost&.throttleStatus&.maximumAvailable
    end

    def points_restore_rate
      extensions&.cost&.throttleStatus&.restoreRate
    end

    def points_maxed?(threshold: 0)
      points_left < threshold
    end
  end
end
