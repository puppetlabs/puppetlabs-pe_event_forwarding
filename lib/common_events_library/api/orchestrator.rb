require_relative '../util/pe_http'

# module Orchestrator this module provides the API specific code for accessing the orchestrator
class Orchestrator
  attr_accessor :pe_client

  def initialize(pe_console, username, password, ssl_verify: true)
    @pe_client = PeHttp.new(pe_console, port: 8143, username: username, password: password, ssl_verify: ssl_verify)
  end

  def get_all_jobs(limit: 0, offset: 0)
    uri = PeHttp.make_pagination_params('orchestrator/v1/jobs', limit, offset)
    pe_client.pe_get_request(uri)
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

  def get_job(job_id, limit = 0, offset = 0)
    uri = PeHttp.make_pagination_params("orchestrator/v1/jobs/#{job_id}", limit, offset)
    pe_client.pe_get_request(uri)
  end

  def self.get_id_from_response(response)
    res = CommonEventsHttp.response_to_hash(response)
    res['job']['name']
  end
end
