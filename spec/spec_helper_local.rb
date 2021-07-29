RSpec.configure do |c|
  c.mock_with :rspec
end

FULL_MODULE_PATH = "#{Dir.pwd}/spec/fixtures/modules".freeze

def procs_paths
  base_path = "#{Dir.pwd}/spec/support/"
  Dir.children('./spec/support').map { |p| "#{base_path}#{p}" } +
    Dir.children('spec/support/acceptance').map { |p| "#{base_path}#{p}" }
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
