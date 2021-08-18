RSpec.configure do |c|
  c.mock_with :rspec
end

def procs_paths
  base_path = "#{Dir.pwd}/spec/support/acceptance/processors/"
  Dir.children(base_path).map { |p| "#{base_path}#{p}" }
end

def capture3_mocks
  f = instance_double(File)
  allow(f).to receive(:write)
  allow(f).to receive(:flush)
  allow(f).to receive(:path).and_return(temp_file_path)
  allow(Tempfile).to receive(:create).and_yield(f)

  exit_status = instance_double(Process::Status)
  allow(exit_status).to receive(:exitstatus).and_return(0)
  invoke_result = ['stdout_message', 'stderr_message', exit_status]
  allow(Open3).to receive(:capture3).with("#{path} #{temp_file_path}").and_return(invoke_result)
end

def index_data(**custom_count)
  template = {
    classifier:     0,
    rbac:           0,
    'pe-console':   0,
    'code-manager': 0,
    orchestrator:   0,
  }
  template.merge(custom_count)
end

def index_yaml(**custom_count)
  index_data(custom_count).to_yaml
end

def events_data(**extra_data)
  require 'json'
  template = {
    rbac: {
      event1: {
        foo: 'bar'
      }
    },
    classifier: {
      event1: {
        foo: 'bar'
      }
    },
    orchestrator: {
      jobs: [
        {
          name: 1,
          description: 'job1'
        },
        {
          name: 2,
          description: 'job2'
        },
      ]
    }
  }

  template.merge(extra_data).to_json
end

def default_settings_hash
  {
    'pe_username' => 'username',
    'pe_password' => 'password',
    'log_level' => 'WARN',
  }
end
