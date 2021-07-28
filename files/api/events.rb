require_relative '../util/pe_http'

module CommonEvents
  # module Events This contains the API specific code for the events API
  class Events
    attr_accessor :pe_client

    def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true)
      @pe_client = CommonEvents::PeHttp.new(pe_console, port: 4433, username: username, password: password, token: token, ssl_verify: ssl_verify)
    end

    def get_events(service: nil, offset: nil, limit: nil, order: 'asc')
      params = {
        service_id: service,
        limit:      limit,
        offset:     offset,
        order:      order,
      }
      uri = CommonEvents::PeHttp.make_params('activity-api/v2/events', params)
      response = pe_client.pe_get_request(uri)
      raise 'Events API request failed' unless response.code == '200'
      JSON.parse(response.body)
    end

    def current_event_count(service_name)
      events_count_for_service = get_events(service: service_name, limit: 1)
      events_count_for_service['pagination']['total'] || 0
    end
  end
end
