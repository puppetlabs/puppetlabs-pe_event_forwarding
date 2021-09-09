#!/usr/bin/env ruby

require_relative '../../pe_event_forwarding/files/api/orchestrator.rb'
require_relative '../../ruby_task_helper/files/task_helper.rb'

# pe_event_forwarding::orchestrator
#
# A class for running orchestrator tasks using the orchestrator API.
# Currently the class is only capable of running the 'facts' task. Additional
# case clauses would be requird to support other operations.
#
# @param [String] console_host
#   The name of the server running the console services and API's.
# @param [String] username
#   A PE username with API priveledges
# @param [String] password
#   The password for the PE User
# @param [String] token
#   An authentication token generated for a PE user than can be used in place
#   of a username and password.
# @param [String] operation
#   The name of the operation to perform using this task.
#   option 1 'run_facts_task'
# @param [String] _body
#   Any data required by an operation. Currently this variable is unused as
#   there is not yet an operation defined that requires a data body.
# @param [String] nodes
#   A list of target nodes to pass to the task. Currently the default is to run
#   the task against local host, which translates to simply using the localhost
#   ruby instance to make the required API calls to the remote console host.
class OrchestratorTask < TaskHelper
  def task(
    console_host: 'localhost',
    username:     'admin',
    password:     'pie',
    token:        nil,
    operation:    nil,
    _body:        nil,
    nodes:        nil,
    **_kwargs
  )

    begin
      orchestrator_client = PeEventForwarding::Orchestrator.new(console_host, username: username, password: password, token: token, ssl_verify: false)
    rescue => exception
      raise TaskHelper::Error.new('Failed to create orchestrator client',
        'orchestator/client-create-error',
        "#{exception}\n#{exception.backtrace}")
    end

    case operation
    when 'run_facts_task'
      targets = []
      targets << (nodes || console_host)
      begin
        response = orchestrator_client.run_facts_task(targets)
        unless response.code == '202'
          raise TaskHelper::Error.new('Failed to run facts job',
            'orchestator/facts-task-run-error',
            "body: #{response.body}\nstatus_code: #{response.code}")
        end
      rescue => e
        raise TaskHelper::Error.new('Failed to run facts job',
          'orchestrator/facts-task-run-http-error',
          "client_hostname: #{orchestrator_client.pe_client.hostname}:#{orchestrator_client.pe_client.port}\n#{e.message}\n#{e.backtrace}")
      end
    end
    puts response.body
  end
end

if __FILE__ == $PROGRAM_NAME
  OrchestratorTask.run
end
