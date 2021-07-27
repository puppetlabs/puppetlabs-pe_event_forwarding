module CommonEvents
  # A class for finding processors and then invoking them.
  # This class should also capture output streams for later logging.
  class Processor
    require 'find'
    require 'open3'

    attr_accessor :path, :stdout, :stderr, :status, :name
    def initialize(path)
      @path = path
      @name = path.split('/')[-1]
    end

    def invoke
      @stdout, @stderr, @status = Open3.capture3(@path)
    end

    def self.find_each(dir)
      return [] unless File.exist? dir
      processors = Find.find(dir).map do |path|
        unless FileTest.directory?(path)
          CommonEvents::Processor.new(path)
        end
      end

      processors.compact
    end
  end
end
