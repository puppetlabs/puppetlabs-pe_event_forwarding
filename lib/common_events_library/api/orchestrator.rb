require_relative '../util/pe_http'

# module Orchestrator this module provides the API specific code for accessing the orchestrator
module Orchestrator
  def get_all_jobs(pe_console, username, password, ssl_verify: true)
    http = PeHttp.new(pe_console, port: 8143, username: username, password: password, ssl_verify: ssl_verify)
    uri = 'orchestrator/v1/jobs'
    http.pe_get_request(uri)
  end
  module_function :get_all_jobs

  def run_facts_task(pe_console, username, password, nodes, ssl_verify: true)
    raise 'run_fact_tasks nodes param requires an array to be specified' unless nodes.is_a? Array
    body = {}
    body['environment'] = 'production'
    body['task'] = 'facts'
    body['params'] = {}
    body['scope'] = {}
    body['scope']['nodes'] = nodes

    http = PeHttp.new(pe_console, port: 8143, username: username, password: password, ssl_verify: ssl_verify)
    uri = 'orchestrator/v1/jobs'
    http.pe_post_request(uri, body)
  end
  module_function :run_facts_task

  def run_job(pe_console, username, password, body, ssl_verify: true)
    http = PeHttp.new(pe_console, port: 8143, username: username, password: password, ssl_verify: ssl_verify)
    uri = '/command/task'
    http.pe_post_request(uri, body)
  end
  module_function :run_job

  def get_job(pe_console, username, password, job_id, limit = 0, offset = 0, ssl_verify: true)
    http = PeHttp.new(pe_console, port: 8143, username: username, password: password, ssl_verify: ssl_verify)
    uri = PeHttp.make_params("orchestrator/v1/jobs/#{job_id}", limit, offset)
    http.pe_get_request(uri)
  end
  module_function :get_job

  def get_id_from_response(response)
    res = CommonEventsHttp.response_to_hash(response)
    res['job']['name']
  end
  module_function :get_id_from_response

  def wait_until_finished(token, pe_console, job_id)
    finished = false

    until finished
      puts "\tWaiting for job=#{job_id} to finish"
      response = get_job(token, pe_console, job_id, ssl_verify: true)
      res = CommonEventsHttp.response_to_hash(response)
      finished = true unless res['status'].select { |x| x['state'] == 'finished' }.empty?
    end
  end
  module_function :wait_until_finished
end
