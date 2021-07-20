module CommonEvents
  # CommonEvents Index utility class for storing and tracking index numbers
  class Index
    attr_accessor :filepath, :index_type
    def initialize(statedir, index_type)
      require 'yaml'
      @filepath = "#{statedir}/common_events_indexes.yaml"
      @index_type = index_type
      create_new_index_file unless File.exist? @filepath
    end

    def create_new_index_file
      tracker = { @index_type => 0 }
      File.write(@filepath, tracker.to_yaml)
      @count = 0
    end

    def count
      @count ||= read_count
    end

    def read_count
      tracker = YAML.safe_load(File.read(@filepath))
      tracker[@index_type] || 0
    end

    def new_items(latest_count)
      diff = latest_count - count
      diff > 0 ? diff : 0
    end

    def index_hash
      YAML.safe_load(File.read(@filepath))
    end

    def save_latest_index(latest)
      data = index_hash
      data[@index_type] = latest
      File.write(@filepath, data.to_yaml)
      @count = nil
    end
  end
end
