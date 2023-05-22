# frozen_string_literal: true

require 'spec_helper'

describe 'pe_event_forwarding::base_path' do
  context 'w/ user provided params' do
    it { is_expected.to run.with_params(nil, '/tmp/').and_return('/tmp') }
    it { is_expected.to run.with_params(nil, '/tmp/conf').and_return('/tmp/conf') }
    it { is_expected.to run.with_params(CONFDIR, '/tmp/pie/conf').and_return('/tmp/pie/conf') }
  end

  context 'w/ default params' do
    it { is_expected.to run.with_params(CONFDIR, nil).and_return('/etc/puppetlabs') }
    it { is_expected.to run.with_params(LOGDIR, nil).and_return('/var/log/puppetlabs') }
    it { is_expected.to run.with_params(LOCKFILEDIR, nil).and_return('/opt/puppetlabs') }
  end
end
