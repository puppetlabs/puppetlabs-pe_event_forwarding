module CommonEvents
  # CommonEvents Index utility class for storing and tracking index numbers
  class Index
    attr_accessor :filepath
    def initialize(statedir)
      require 'yaml'
      @filepath = "#{statedir}/common_events_indexes.yaml"
      @first_run = false

      new_index_file unless File.exist? @filepath
    end

    def new_index_file
      tracker = { classifier:     0,
                  rbac:           0,
                  'pe-console':   0,
                  'code-manager': 0,
                  orchestrator:   0, }
      File.write(filepath, tracker.to_yaml)
      @first_run = true
    end

    def first_run?
      @first_run
    end

    def counts(refresh: false)
      if refresh
        @counts = YAML.safe_load(File.read(filepath), [Symbol])
      end
      @counts ||= YAML.safe_load(File.read(filepath), [Symbol])
    end

    def count(service)
      counts[service] || 0
    end

    def new_items(service, latest_count)
      diff = latest_count - count(service)
      raise 'Got negative value for new_items' unless diff >= 0
      diff
    end

    def save(**service)
      data = counts(refresh: true)
      service.each do |key, value|
        next if value.nil?
        data[key] = value.is_a?(Integer) ? value : value['pagination']['total']
      end
      File.write(filepath, data.to_yaml)
      @counts = data
    end

    def add(service, increment)
      total = count(service) + increment
      save(service => total)
    end
  end
end
