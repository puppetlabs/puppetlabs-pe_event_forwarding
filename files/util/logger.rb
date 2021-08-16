require 'logger'
require 'json'

module CommonEvents
  # CommonEvents Logger class that inherits from Logger
  class Logger < ::Logger
    LOG_LEVELS = {
      'DEBUG' => Logger::DEBUG,
      'INFO'  => Logger::INFO,
      'WARN'  => Logger::WARN,
      'ERROR' => Logger::ERROR,
      'FATAL' => Logger::FATAL
    }.freeze

    def initialize(log_path, shift_age)
      shift_age = shift_age == 'NONE' ? 0 : shift_age.downcase
      super(log_path, shift_age)
      self.datetime_format = '%Y-%m-%d %H:%M:%S'

      self.formatter = proc do |severity, datetime, progname, msg|
        orig_log_data = JSON.parse(msg)
        log_data = {
          date: datetime,
          severity: severity,
          source: progname,
          message: orig_log_data['message'],
          exit_code: orig_log_data['exit_code'],
        }.to_json
        "#{log_data}\n"
      end
    end

    def info(msg, exit_code: 0, source: 'common_events')
      message = {
        message: msg,
        exit_code: exit_code
      }.to_json
      super(source) { message }
    end

    def fatal(msg, exit_code: 0, source: 'common_events')
      message = {
        message: msg,
        exit_code: exit_code
      }.to_json
      super(source) { message }
    end

    def warn(msg, exit_code: 0, source: 'common_events')
      message = {
        message: msg,
        exit_code: exit_code
      }.to_json
      super(source) { message }
    end
  end
end
