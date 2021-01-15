module CommonEvents
  # Normalize and parse the return data from the API
  class OrchestratorResult
    attr_accessor :total, :items, :raw
    def initialize(res)
      data   = JSON.parse(res.body)
      @total = data['pagination']['total'] || 0
      @items = data['items']
      @raw   = data
    end
  end
end
