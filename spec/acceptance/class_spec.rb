
require 'spec_helper_acceptance'

describe 'Verify the minimum install' do
  before(:all) do
    set_sitepp_content(declare('class', 'pe_event_forwarding', { 'pe_token' => auth_token }.merge(cron_schedule)))
    trigger_puppet_run(puppetserver)
  end

  after(:all) do
    set_sitepp_content(declare('class', 'pe_event_forwarding', { 'pe_token' => auth_token, 'disabled' => true }))
    trigger_puppet_run(puppetserver)
  end

  describe 'places files correctly' do
    it 'api class folder' do
      directory = "#{CONFDIR}/pe_event_forwarding/api"
      expect(puppetserver.directory_exists?(directory)).to be true
    end

    it 'util class folder' do
      directory = "#{CONFDIR}/pe_event_forwarding/util"
      expect(puppetserver.directory_exists?(directory)).to be true
    end

    it 'collection_settings.yaml' do
      yaml_file = "#{CONFDIR}/pe_event_forwarding/collection_settings.yaml"
      expect(puppetserver.file_exists?(yaml_file)).to be true
    end

    it 'collection_secrets.yaml' do
      yaml_file = "#{CONFDIR}/pe_event_forwarding/collection_secrets.yaml"
      expect(puppetserver.file_exists?(yaml_file)).to be true
    end

    it 'collect_api_events.rb' do
      script_file = "#{CONFDIR}/pe_event_forwarding/collect_api_events.rb"
      expect(puppetserver.file_exists?(script_file)).to be true
    end

    it 'processors.d folder' do
      script_file = "#{CONFDIR}/pe_event_forwarding/processors.d"
      expect(puppetserver.directory_exists?(script_file)).to be true
    end
  end

  describe 'it removes old settings file' do
    it 'events_collection.yaml' do
      yaml_file = "#{CONFDIR}/pe_event_forwarding/events_collection.yaml"
      expect(puppetserver.file_exists?(yaml_file)).to be false
    end
  end

  describe 'configures cron' do
    it 'enables cron' do
      result = puppetserver.run_shell('crontab -u pe-puppet -l', expect_failures: true).stdout
      expect(result.include?('collect_api_events.rb')).to be true
    end

    it 'applies the correct schedule' do
      result = puppetserver.run_shell('crontab -u pe-puppet -l', expect_failures: true).stdout
      expect(result.include?('10 9 6 7 3')).to be true
    end
  end
end
