require_relative '../util/pe_http'

module PeEventForwarding
  # module Orchestrator this module provides the API specific code for accessing the orchestrator
  class Orchestrator
    attr_accessor :pe_client

    def initialize(pe_console, username: nil, password: nil, token: nil, ssl_verify: true)
      @pe_client = PeEventForwarding::PeHttp.new(pe_console, port: 8143, username: username, password: password, token: token, ssl_verify: ssl_verify)
    end

    def get_jobs(offset: 0, order: 'asc', order_by: 'name', api_window_size: nil)
      params = {
        limit:    api_window_size,
        offset:   offset,
        order:    order,
        order_by: order_by,
      }

      api_window_size = api_window_size.to_i
      response_items  = []
      response        = ''
      total_count     = 0
      loop do
        response       = pe_client.pe_get_request('orchestrator/v1/jobs', params)
        response_body  = JSON.parse(response.body)
        total_count    = response_body['pagination']['total']
        response_body['items']&.map { |item| response_items << item }

        break if response_body['items'].nil? || response_body['items'].count != api_window_size
        params[:offset] += api_window_size
      end
      raise 'Orchestrator API request failed' unless response.code == '200'
      { 'pagination' => { 'total' => total_count }, 'items' => response_items }
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

    def current_job_count
      params = {
        limit:    1,
        offset:   0,
        order:    'asc',
        order_by: 'name',
      }
      response = pe_client.pe_get_request('orchestrator/v1/jobs', params)
      raise 'Orchestrator API request failed' unless response.code == '200'
      jobs = JSON.parse(response.body)
      jobs['pagination']['total'] || 0
    end

    def new_data(last_count, api_window_size)
      new_job_count = current_job_count - last_count
      return unless new_job_count > 0
      get_jobs(offset: last_count, api_window_size: api_window_size)
    end
  end
end
