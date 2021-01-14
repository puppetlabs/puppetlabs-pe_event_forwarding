module CommonEvents
  # Normalize and parse the return data from the API
  class ActivityServiceResult
    attr_accessor :total, :items, :raw
    def initialize(res)
      data   = JSON.parse(res.body)
      @total = data['total-rows'] || 0
      @items = data['commits']
      @raw   = data
    end
  end
end
