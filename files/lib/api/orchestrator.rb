require_relative '../util/pe_http'

# module Orchestrator this module provides the API specific code for accessing the orchestrator
class Orchestrator
  attr_accessor :pe_client

  def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true)
    @pe_client = PeHttp.new(pe_console, port: 8143, username: username, password: password, token: token, ssl_verify: ssl_verify)
  end

  def get_jobs(limit: nil, offset: nil, order: nil, order_by: nil)
    params = {
      limit:    limit,
      offset:   offset,
      order:    order,
      order_by: order_by,
    }

    uri = PeHttp.make_params('orchestrator/v1/jobs', params)
    response = pe_client.pe_get_request(uri)
    raise 'Orchestrator API request failed' unless response.code == '200'
    response.body
  end

  def run_facts_task(nodes)
    raise 'run_fact_tasks nodes param requires an array to be specified' unless nodes.is_a? Array
    body = {}
    body['environment'] = 'production'
    body['task'] = 'facts'
    body['params'] = {}
    body['scope'] = {}
    body['scope']['nodes'] = nodes

    uri = 'orchestrator/v1/command/task'
    pe_client.pe_post_request(uri, body)
  end

  def run_job(body)
    uri = '/command/task'
    pe_client.pe_post_request(uri, body)
  end

  def get_job(job_id)
    response = pe_client.pe_get_request("orchestrator/v1/jobs/#{job_id}")
    JSON.parse(response.body)
  end

  def self.get_id_from_response(response)
    res = CommonEventsHttp.response_to_hash(response)
    res['job']['name']
  end
end
