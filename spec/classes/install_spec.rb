# frozen_string_literal: true

require 'spec_helper'

describe 'common_events::install' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:confdir) { 'bluh' }
      let(:confdir_expectation) { File.join(Dir.pwd, 'bluh') }
      let(:logdir) { "#{Puppet.settings.setting('logdir').value}/common_events/common_events.log" }
      let(:facts) do
        facts.merge(pe_server_version: '2019.8.7')
      end

      context 'with cron enabled' do
        let(:pre_condition) do
          <<-PRE_COND
            class {'common_events':
              pe_token => 'blah',
            }
        PRE_COND
        end

        it {
          is_expected.to contain_file("#{confdir_expectation}/common_events")
            .with(
            ensure: 'directory',
          )
        }

        it {
          is_expected.to contain_file("#{confdir_expectation}/common_events/api")
            .with(
            ensure: 'directory',
          )
        }

        it {
          is_expected.to contain_file("#{confdir_expectation}/common_events/util")
            .with(
            ensure: 'directory',
          )
        }

        it {
          is_expected.to contain_file("#{confdir_expectation}/common_events/events_collection.yaml")
            .with(
            ensure: 'file',
            require: "File[#{confdir_expectation}/common_events]",
          )
        }

        it {
          is_expected.to contain_file("#{confdir_expectation}/common_events/collect_api_events.rb")
            .with(
            ensure: 'file',
            mode: '0755',
            require: "File[#{confdir_expectation}/common_events]",
          )
        }

        it {
          is_expected.to contain_cron('collect_common_events')
            .with_command("#{confdir_expectation}/common_events/collect_api_events.rb" \
            " #{confdir_expectation}/common_events" \
            " #{logdir}")
        }
      end

      context 'with cron disabled' do
        let(:pre_condition) do
          <<-PRE_COND
            class {'common_events':
              pe_token => 'blah',
              disabled => true,
            }
        PRE_COND
        end

        it {
          is_expected.to contain_cron('collect_common_events')
            .with(
            ensure: 'absent',
          )
        }
      end
    end
  end
end
