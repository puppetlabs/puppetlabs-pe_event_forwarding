require_relative '../util/pe_http'

module PeEventForwarding
  # module Orchestrator this module provides the API specific code for accessing the orchestrator
  class Orchestrator
    attr_accessor :pe_client, :log

    def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true, log: nil)
      @pe_client = PeEventForwarding::PeHttp.new(pe_console, port: 8143, username: username, password: password, token: token, ssl_verify: ssl_verify, log: log)
      @log = log
    end

    def get_jobs(limit: 500, offset: 0, order: 'desc', order_by: 'name', index_count: nil, new_jobs: nil, timeout: nil)
      params = {
        limit:    limit,
        offset:   offset,
        order:    order,
        order_by: order_by,
      }

      response_items  = []
      response        = ''
      job_counter     = 0
      total_count     = index_count + new_jobs
      loop do
        response       = pe_client.pe_get_request('orchestrator/v1/jobs', params, timeout)
        response_body  = JSON.parse(response.body)
        response_body['items']&.map { |item| response_items << item }

        job_counter += response_body['items'].empty? ? 0 : response_body['items'].count
        break if job_counter >= new_jobs
        params[:offset] = job_counter
        params[:limit] = if new_jobs - job_counter > limit
                           limit
                         else
                           new_jobs - job_counter
                         end
      end
      log.debug("PE Get Jobs Items Found: #{response_items.count}")
      raise 'Orchestrator API request failed' unless response.code == '200'
      { 'api_total_count' => total_count, 'events' => response_items }
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
      res = PeEventForwarding::Http.response_to_hash(response)
      res['job']['name']
    end

    def current_job_count(timeout)
      params = {
        limit:    1,
        offset:   0,
        order:    'desc',
        order_by: 'name',
      }
      response = pe_client.pe_get_request('orchestrator/v1/jobs', params, timeout)
      raise 'Orchestrator API request failed' unless response.code == '200'
      jobs = JSON.parse(response.body)
      jobs['items'].empty? ? 0 : jobs['items'][0]['name'].to_i
    end

    def new_data(last_count, timeout)
      new_job_count = current_job_count(timeout) - last_count
      if new_job_count.zero? || new_job_count.negative?
        log.debug('New Job Count: Orchestrator: data is current')
        nil
      else
        log.debug("New Job Count: Orchestrator: #{new_job_count}")
        get_jobs(index_count: last_count, new_jobs: new_job_count, timeout: timeout)
      end
    end
  end
end
