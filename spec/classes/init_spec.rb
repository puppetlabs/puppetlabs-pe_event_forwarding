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
      let(:facts) do
        facts.merge(pe_server_version: '2019.8.7')
      end

      it { is_expected.to compile }
    end
  end
end
