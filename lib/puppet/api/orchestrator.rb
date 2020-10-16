require_relative '../util/http'

# module Orchestrator this module provides the API specific code for accessing the orchestrator
module Orchestrator
  def get_all_jobs(token, pe_console)
    auth_header = { 'X-Authentication' => token.to_s }
    Http.get_request(pe_console, 8143, 'orchestrator/v1/jobs', auth_header)
  end
  module_function :get_all_jobs
end
