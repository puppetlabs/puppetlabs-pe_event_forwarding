require_relative '../util/http'

# module Orchestrator this module provides the API specific code for accessing the orchestrator
module Orchestrator
  def get_all_jobs(token, pe_console, ssl_verify: true)
    Http.get_request(pe_console, 8143, 'orchestrator/v1/jobs', token: token, destination: 'pe', ssl_verify: ssl_verify)
  end
  module_function :get_all_jobs

  def run_facts_task(token, pe_console, nodes, ssl_verify: true)
    raise 'run_fact_tasks nodes param requires an array to be specified' unless nodes.is_a? Array
    body = {}
    body['environment'] = 'production'
    body['task'] = 'facts'
    body['params'] = {}
    body['scope'] = {}
    body['scope']['nodes'] = nodes

    Http.post_request(pe_console, 8143, 'orchestrator/v1/command/task', body, token: token, destination: 'pe', ssl_verify: ssl_verify)
  end
  module_function :run_facts_task

  def run_job(token, pe_console, body, ssl_verify: true)
    Http.post_request(pe_console, 8143, '/command/task', body, token: token, destination: 'pe', ssl_verify: ssl_verify)
  end
  module_function :run_job

  def get_job(token, pe_console, job_id, limit = 0, offset = 0, ssl_verify: true)
    Http.get_request(pe_console, 8143, Http.make_params("orchestrator/v1/jobs/#{job_id}", limit, offset), token: token, destination: 'pe', ssl_verify: ssl_verify)
  end
  module_function :get_job

  def get_id_from_response(response)
    res = Http.response_to_hash(response)
    res['job']['name']
  end
  module_function :get_id_from_response

  def wait_until_finished(token, pe_console, job_id)
    finished = false

    until finished
      puts "\tWaiting for job=#{job_id} to finish"
      response = get_job(token, pe_console, job_id)
      res = Http.response_to_hash(response)
      finished = true unless res['status'].select { |x| x['state'] == 'finished' }.empty?
    end
  end
  module_function :wait_until_finished
end
