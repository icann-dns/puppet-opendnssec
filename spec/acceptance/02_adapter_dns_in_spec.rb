# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'opendnssec class' do
  context 'defaults' do
    it 'work with no errors' do
      pp = <<-EOF
      class {'::softhsm':
        tokens => {
          'OpenDNSSEC' => {
            'pin'    => '1234',
            'so_pin' => '1234',
          },
        },
      }
      class {'::opendnssec': 
        policies => { 'test_policy' => {} },
        zones => { 'root-servers.net' => { 'policy' => 'test_policy' } },
        remotes  => {
          'master' => { 'address4' => '192.0.2.1' },
          'provide_xfr' => { 'address4' => '192.0.2.2' },
        },
      }
      EOF
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
    describe service('opendnssec-enforcer') do
      it { is_expected.to be_running }
    end
    describe service('opendnssec-signer') do
      it { is_expected.to be_running }
    end
    describe port(53) do
      it { is_expected.to be_listening }
    end
  end
end
