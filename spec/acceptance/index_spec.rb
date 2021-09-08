require 'spec_helper_acceptance'
require 'yaml'

describe 'index file' do
  before(:all) do
    puppetserver.run_shell("#{CONFDIR}/pe_event_forwarding/collect_api_events.rb")
  end

  it 'index file exists' do
    expect(puppetserver.file_exists?("#{CONFDIR}/pe_event_forwarding/pe_event_forwarding_indexes.yaml")).to be true
  end

  it 'writes expected keys' do
    index_contents = puppetserver.run_shell("cat #{CONFDIR}/pe_event_forwarding/pe_event_forwarding_indexes.yaml").stdout
    index = YAML.safe_load(index_contents, [Symbol])
    [:classifier, :rbac, :'pe-console', :'code-manager', :orchestrator].each do |key|
      expect(index.keys.include?(key)).to be true
    end
  end

  it 'updates orchestrator index value' do
    index_contents = puppetserver.run_shell("cat #{CONFDIR}/pe_event_forwarding/pe_event_forwarding_indexes.yaml").stdout
    index          = YAML.safe_load(index_contents, [Symbol])
    current_value  = index[:orchestrator]
    puppetserver.run_shell("puppet task run facts --nodes #{console_host_fqdn}")
    index_contents = puppetserver.run_shell("#{CONFDIR}/pe_event_forwarding/collect_api_events.rb ; cat #{CONFDIR}/pe_event_forwarding/pe_event_forwarding_indexes.yaml").stdout
    index = YAML.safe_load(index_contents, [Symbol])
    updated_value = index[:orchestrator]
    expect(updated_value).to eql(current_value + 1)
  end
end
