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
      class {'::opendnssec': }
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
