# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'opendnssec file adapter in dns adapter out with default TSIG', tier_medium: true do
  context 'defaults' do
    if fact('osfamily') == 'RedHat'
      enforcer = 'ods-enforcerd'
      signer = 'ods-signerd'
    else
      enforcer = 'opendnssec-enforcer'
      signer = 'opendnssec-signer'
    end
    it 'work with no errors' do
      # rubocop:disable Layout/IndentHeredoc
      example_zone = <<EOS
example.com. 3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. 1 7200 3600 1209600 3600
example.com. 86400 IN NS a.iana-servers.net.
example.com. 86400 IN NS b.iana-servers.net.
EOS
      # rubocop:enable Layout/IndentHeredoc
      pp = <<-EOF
      class {'::softhsm':
        tokens => {
          'OpenDNSSEC' => {
            'pin'    => '1234',
            'so_pin' => '1234',
          },
        },
      }
      class {'::nsd':
        port    => 5353,
        zones   => { 'example.com' => { 'masters' => ['localhost'] } },
        remotes => { 'localhost' => { 'address4' => '127.0.0.1' } },
        tsigs   => {
          'test_tsig' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          },
        },
        default_tsig_name => 'test_tsig',
      }
      class {'::opendnssec':
        tsigs   => {
          'test_tsig' => {
            'data' => 'qneKJvaiXqVrfrS4v+Oi/9GpLqrkhSGLTCZkf0dyKZ0='
          },
        },
        default_tsig_name => 'test_tsig',
        zones => {
          'example.com' => {
            'zone_content' => '#{example_zone}',
            'adapter_input_type' => 'File',
            'provide_xfrs' => ['localhost'],
          },
        },
        remotes  => {
          'localhost' => {
            'address4' => '127.0.0.1',
            'port' => 5353,
          },
        },
      }
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
    describe service('nsd') do
      it { is_expected.to be_running }
    end
    describe port(53) do
      it { is_expected.to be_listening }
    end
    describe port(5353) do
      it { is_expected.to be_listening }
    end
    describe command('/usr/bin/ods-ksmutil repository list') do
      its(:stdout) { is_expected.to match(%r{SoftHSM\s+0\s+No}) }
    end
    describe command('/usr/bin/ods-ksmutil policy list') do
      its(:stdout) do
        is_expected.to match(
          %r{default\s+default - Deny:NSEC3; KSK:RSASHA1-NSEC3-SHA1; ZSK:RSASHA1-NSEC3-SHA1},
        )
      end
    end
    describe command('/usr/bin/ods-ksmutil zone list') do
      its(:stdout) do
        is_expected.to match('Found Zone: example.com; on policy default')
      end
    end
    describe command('/usr/bin/ods-ksmutil key list') do
      its(:stdout) { is_expected.to match(%r{example.com\s+KSK\s+publish}) }
      its(:stdout) { is_expected.to match(%r{example.com\s+ZSK\s+active}) }
    end
    describe command('/usr/sbin/ods-signer zones') do
      its(:stdout) { is_expected.to match('example.com') }
    end
    describe command(
      '/usr/bin/dig -p 5353 +dnssec soa example.com @localhost',
    ) do
      its(:stdout) { is_expected.to match(%r{\bRRSIG\b}) }
    end
  end
end
