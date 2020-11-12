#!/usr/bin/env ruby
require_relative '../../ruby_task_helper/files/task_helper.rb'
require_relative '../lib/common-events_library/util/http'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'time'

# CreateScheduledTask will construct a scheduled task in PE
class CreateScheduledTask < TaskHelper
  def task(
    task:            nil,
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

    if auth_token.nil?
      auth_token = Http.get_token(
        puppetserver,
        username,
        password,
        ssl_verify: ssl_verify,
        ca_cert_path: ca_cert_path,
      )
    end

    headers = { 'X-Authentication' => auth_token, 'Content-Type' => 'application/json' }

    data = {
      environment: environment,
      task: task,
      params: {},
      scope: {
        nodes: [
          puppetserver.prepend(puppetserver.start_with?('https://') ? '' : 'https://'),
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

    response = Http.post_request(
      puppetserver,
      8143,
      'orchestrator/v1/command/schedule_task',
      data,
      headers,
      ssl_verify: ssl_verify,
      ca_cert_path: ca_cert_path,
    )

    if response.code == '202'
      {
        body:    JSON.parse(response.body),
        code:    response.code,
        message: response.message,
      }
    else
      additional_info = {
        body: JSON.parse(response.body),
        http_status: response.code,
        message: response.message,
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
