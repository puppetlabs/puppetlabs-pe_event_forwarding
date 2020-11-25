require_relative '../util/pe_http'

# module Events This contains the API specific code for the events API
class Events
  attr_accessor :pe_client

  def initialize(pe_console, username, password, ssl_verify: true)
    @pe_client = PeHttp.new(pe_console, port: 4433, username: username, password: password, ssl_verify: ssl_verify)
  end

  def get_all_events(service: 'classifier', offset: 0, limit: 0)
    uri = PeHttp.make_pagination_params("activity-api/v1/events?service_id=#{service}", limit, offset)
    pe_client.pe_get_request(uri)
  end
end
