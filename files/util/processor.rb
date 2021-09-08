module CommonEvents
  # A class for finding processors and then invoking them.
  # This class should also capture output streams for later logging.
  class Processor
    require 'find'
    require 'open3'

    attr_accessor :path, :stdout, :stderr, :status, :name, :exitcode
    def initialize(path)
      @path = path
      @name = path.split('/')[-1]
    end

    def invoke(data)
      require 'tempfile'
      Tempfile.create(name) do |f|
        f.write(data.to_json)
        f.flush
        @stdout, @stderr, @status = Open3.capture3("#{path} #{f.path}")
        @exitcode = status.exitstatus
      end
    end

    def self.find_each(dir)
      return [] unless File.exist? dir
      dir_listing(dir).select do |path|
        unless FileTest.directory?(path)
          processor = CommonEvents::Processor.new(path)
          block_given? ? yield(processor) : processor
        end
      end
    end

    # Tiny little wrapper to make test mocks easier.
    def self.dir_listing(dir)
      Dir["#{dir}/*"]
    end
  end
end
