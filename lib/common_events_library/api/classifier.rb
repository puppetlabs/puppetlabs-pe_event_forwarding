require_relative '../util/http'

# module Classifier. This contains the API specific code to retreive information
# from the classifier api.
module Classifier
  # Since we don't know exactly what we'll call these parameters yet this method
  # just fetches all parameters for a node. Eventually we plan to store job_ids,
  # pagination information, and possibly auth information for third party
  # services such as Splunk.
  def get_node_parameters(token, pe_console, node, ssl_verify = true, offset = 0, limit = 0)
    response = Http.get_request(pe_console, 4433, Http.make_params("classifier-api/v1/classified/nodes/#{node}", limit, offset), token: token, destination: 'pe', ssl_verify: ssl_verify)
    raise "Failed to retreive node parameters: #{response.code}, #{response.message}" if response.code.to_i > 200
    JSON.parse(response.body)['parameters']
  end
  module_function :get_node_parameters
end
