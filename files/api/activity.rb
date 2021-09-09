require_relative '../util/pe_http'

module PeEventForwarding
  # module Events This contains the API specific code for the events API
  class Activity
    SERVICE_NAMES = [:classifier, :rbac, :'pe-console', :'code-manager' ].freeze

    attr_accessor :pe_client

    def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true)
      @pe_client = PeEventForwarding::PeHttp.new(pe_console, port: 4433, username: username, password: password, token: token, ssl_verify: ssl_verify)
    end

    def get_events(service: nil, offset: nil, limit: nil, order: 'asc')
      params = {
        service_id: service,
        limit:      limit,
        offset:     offset,
        order:      order,
      }
      response = pe_client.pe_get_request('activity-api/v2/events', params)
      raise 'Events API request failed' unless response.code == '200'
      JSON.parse(response.body)
    end

    def current_event_count(service_name)
      events_count_for_service = get_events(service: service_name, limit: 1)
      events_count_for_service['pagination']['total'] || 0
    end

    def new_data(service, last_count)
      new_count = current_event_count(service) - last_count
      return unless new_count > 0
      get_events(service: service, offset: last_count, limit: new_count)
    end
  end
end
