require_relative '../util/http'

# module Events This contains the API specific code for the events API
module Events
  def get_all_events(token, pe_console, service = 'classifier', offset = 0, limit = 0, ssl_verify: true)
    Http.get_request(pe_console, 4433, Http.make_params("activity-api/v1/events?service_id=#{service}", limit, offset), destination: 'pe', token: token, ssl_verify: ssl_verify)
  end
  module_function :get_all_events
end
