require_relative '../util/pe_http'

module PeEventForwarding
  # module Events This contains the API specific code for the events API
  class Activity
    SERVICE_NAMES = [:classifier, :rbac, :'pe-console', :'code-manager' ].freeze
    API_END_POINT = 'activity-api/v2/events'.freeze

    attr_accessor :pe_client, :log

    def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true, log: nil)
      @pe_client = PeEventForwarding::PeHttp.new(pe_console, port: 4433, username: username, password: password, token: token, ssl_verify: ssl_verify, log: log)
      @log = log
    end

    def get_events(service: nil, offset: 0, order: 'asc', api_page_size: nil, timeout: nil)
      params = {
        service_id: service,
        limit:      api_page_size,
        offset:     offset,
        order:      order,
      }

      api_page_size = api_page_size.to_i
      response_items = []
      response       = ''
      total_count    = 0
      loop do
        response       = pe_client.pe_get_request(API_END_POINT, params, timeout)
        response_body  = JSON.parse(response.body)
        total_count    = response_body['pagination']['total']
        response_body['commits']&.map { |commit| response_items << commit }

        break if response_body['commits'].nil? || response_body['commits'].count != api_page_size
        params[:offset] += api_page_size
      end
      log.debug("PE Get Events Items Found: #{service}: #{response_items.count}")
      raise 'Events API request failed' unless response.code == '200'
      { 'api_total_count' => total_count, 'events' => response_items }
    end

    def current_event_count(service_name, timeout)
      params = {
        service_id: service_name,
        limit:      1,
        offset:     0,
        order:      'asc',
      }
      response = pe_client.pe_get_request(API_END_POINT, params, timeout)
      raise 'Events API request failed' unless response.code == '200'
      events_count_for_service = JSON.parse(response.body)
      events_count_for_service['pagination']['total'] || 0
    end

    def new_data(service, last_count, api_page_size, timeout)
      new_count = current_event_count(service, timeout) - last_count
      log.debug("New Event Count: #{service}: #{new_count}")
      return unless new_count > 0
      get_events(service: service, offset: last_count, api_page_size: api_page_size, timeout: timeout)
    end
  end
end
