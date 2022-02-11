require 'json'

module PeEventForwarding
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

    def same_pid_as_lockfile?
      info['pid'] == Process.pid
    end

    # The force argument will delete the lockfile even if it does not belong to the current process.
    # This is useful if we have confirmed the process is no longer running.
    def remove_lockfile(force: false)
      raise 'Cannot delete Lockfile. Does not exist.' unless lockfile_exists?
      File.delete(filepath) if force || same_pid_as_lockfile?
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
      remove_lockfile(force: true)
      false
    end
  end
end
