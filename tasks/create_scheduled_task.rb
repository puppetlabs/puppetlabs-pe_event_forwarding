#!/usr/bin/env ruby
require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/common_events_library/util/pe_http.rb'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'time'

# CreateScheduledTask will construct a scheduled task in PE
class CreateScheduledTask < TaskHelper
  def task(
    task:            nil,
    task_params:     nil,
    description:     nil,
    interval:        60,
    scheduled_time:  nil,
    environment:     'production',
    puppetserver:    nil,
    auth_token:      nil,
    username:        nil,
    password:        nil,
    ca_cert_path:    nil,
    skip_cert_check: false,
    **_kwargs
  )

    scheduled_time = scheduled_time.nil? ? Time.now + 30 : Time.parse(scheduled_time)
    scheduled_time = scheduled_time.utc.iso8601

    ssl_verify = !skip_cert_check

    data = {
      environment: environment,
      task: task,
      description: description,
      params: task_params || {},
      scope: {
        nodes: [
          puppetserver,
        ],
      },
      scheduled_time: scheduled_time,
      schedule_options: {
        interval: {
          units: 'seconds',
          value: interval,
        },
      },
    }

    pe_client = PeHttp.new(
      puppetserver,
      port:         8143,
      username:     username,
      password:     password,
      token:        auth_token,
      ca_cert_path: ca_cert_path,
      ssl_verify:   ssl_verify,
    )

    response = pe_client.pe_post_request(
      'orchestrator/v1/command/schedule_task',
      data,
    )

    if response.code == '202'
      {
        body:    JSON.parse(response.body),
        code:    response.code,
        message: response.message,
      }
    else
      additional_info = {
        body:        JSON.parse(response.body),
        http_status: response.code,
        message:     response.message,
      }

      raise TaskHelper::Error.new(
        "Failed to create scheduled task: #{JSON.parse(response.body)['msg']}",
        'common_integration_events/task-create-failure',
        additional_info,
      )

    end
  end
end

CreateScheduledTask.run if $PROGRAM_NAME == __FILE__
