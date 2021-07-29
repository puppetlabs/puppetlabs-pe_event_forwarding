module CommonEvents
  # CommonEvents Index utility class for storing and tracking index numbers
  class Index
    attr_accessor :filepath
    def initialize(statedir)
      require 'yaml'
      @filepath = "#{statedir}/common_events_indexes.yaml"

      create_new_index_file unless File.exist? @filepath
    end

    def create_new_index_file
      tracker = { classifier:     0,
                  rbac:           0,
                  'pe-console':   0,
                  'code-manager': 0,
                  orchestrator:   0, }
      File.write(filepath, tracker.to_yaml)
    end

    def counts
      @counts ||= YAML.safe_load(File.read('tracker.yaml'), [Symbol])
    end

    def read_count(index_type)
      tracker = YAML.safe_load(File.read(filepath), [Symbol])
      tracker[index_type] || 0
    end

    def new_items(index_type, latest_count)
      diff = latest_count - read_count(index_type)
      raise 'Got negative value for new_items' unless diff >= 0
      diff
    end

    def index_hash
      YAML.safe_load(File.read(filepath), [Symbol])
    end

    def save_latest_index(index_type, latest)
      data = index_hash
      data[index_type] = latest
      File.write(filepath, data.to_yaml)
      @counts = data
    end
  end
end
