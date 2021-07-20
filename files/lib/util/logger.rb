require 'logger'
require 'json'

module CommonEvents
  # CommonEvents Logger class that inherits from Logger
  class Logger < ::Logger
    def initialize(log_path = '/var/log/puppetlabs/common_events.json')
      super(log_path)
      self.datetime_format = '%Y-%m-%d %H:%M:%S'

      self.formatter = proc do |severity, datetime, progname, msg|
        log_data = {
          date: datetime,
          severity: severity,
          source: progname,
          message: msg,
        }.to_json
        "#{log_data}\n"
      end
    end

    def info(msg, source: 'common_events')
      super(source) { msg }
    end

    def fatal(msg, source: 'common_events')
      super(source) { msg }
    end

    def warn(msg, source: 'common_events')
      super(source) { msg }
    end
  end
end
