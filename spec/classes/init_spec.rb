# frozen_string_literal: true

require 'spec_helper'

describe 'common_events' do
  let(:params) do
    {
      pe_token: 'blah',
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:confdir) { 'bluh' }
      let(:confdir_expectation) { File.join(Dir.pwd, 'bluh') }
      let(:facts) do
        facts.merge(pe_server_version: '2019.8.7')
      end

      it { is_expected.to compile }

      context 'with cron enabled' do
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
            .with_command(%r{collect_api_events.rb*.*common_events.log*.*\/state\/common_events\/cache\/state})
        }
      end

      context 'with cron disabled' do
        let(:params) do
          {
            pe_token: 'blah',
            disabled: true,
          }
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
