require 'spec_helper'

RSpec.configure do |c|
  c.mock_with :rspec
end

FULL_MODULE_PATH = "#{Dir.pwd}/spec/fixtures/modules".freeze

def procs_paths
  base_path = "#{Dir.pwd}/spec/support/"
  Dir.children('./spec/support').map { |p| "#{base_path}#{p}" } +
    Dir.children('spec/support/acceptance').map { |p| "#{base_path}#{p}" }
end
