# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'opendnssec class', tier_low: true do
  context 'defaults' do
    if fact('osfamily') == 'RedHat'
      enforcer = 'ods-enforcerd'
      signer = 'ods-signerd'
    else
      enforcer = 'opendnssec-enforcer'
      signer = 'opendnssec-signer'
    end
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
    describe service(enforcer) do
      it { is_expected.to be_running }
    end
    describe service(signer) do
      it { is_expected.to be_running }
    end
    describe port(53) do
      it { is_expected.to be_listening }
    end
  end
end
