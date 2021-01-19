require_relative '../util/pe_http'

# module Events This contains the API specific code for the events API
class Events
  attr_accessor :pe_client

  def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true)
    @pe_client = PeHttp.new(pe_console, port: 4433, username: username, password: password, token: token, ssl_verify: ssl_verify)
  end

  def get_events(service: nil, offset: nil, limit: nil)
    params = {
      service_id: service,
      limit:      limit,
      offset:     offset,
    }
    uri = PeHttp.make_params('activity-api/v1/events', params)
    response = pe_client.pe_get_request(uri)
    raise 'Events API request failed' unless response.code == '200'
    CommonEvents::ActivityServiceResult.new(response)
  end
end
