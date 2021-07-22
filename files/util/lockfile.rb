require 'json'

module CommonEvents
  # Manages the Lockfile.
  class Lockfile
    attr_accessor :filepath

    def initialize(basepath)
      @filepath = File.join(basepath, 'events_collection_run.lock')
    end

    def lockfile_exists?
      File.exist? filepath
    end

    def info
      if lockfile_exists?
        JSON.parse(File.read(filepath))
      else
        { pid: nil, program_name: '' }
      end
    end

    def write_lockfile
      raise 'Cannot acquire lock. Lockfile already exists.' if lockfile_exists? && info['pid']
      body = {
        pid:          Process.pid,
        program_name: $PROGRAM_NAME,
      }

      File.write(filepath, body.to_json)
    end

    def remove_lockfile
      raise 'Cannot delete Lockfile. Does not exist.' unless lockfile_exists?
      File.delete(filepath)
    end

    def already_running?
      pid = info['pid']
      pid.nil? ? false : validate_command(pid)
    end

    def validate_command(pid)
      command = File.read("/proc/#{pid}/cmdline")
      !info['program_name'].match(%r{#{command}}).nil?
    rescue
      # Remove lock if the process is no longer running.
      remove_lockfile
      false
    end
  end
end
