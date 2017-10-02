# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::addns' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_addns' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      # masters: ['master'],
      # provide_xfrs: [],

    }
  end
  let(:pre_condition) do
    <<-EOF
    class { '::opendnssec':
      policies => {'test_policy' => {} },
      remotes  => {
        'master' => { 'address4' => '192.0.2.1' },
        'provide_xfr' => { 'address4' => '192.0.2.2' },
      },
    }
    EOF
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_opendnssec__addns('test_addns') }
        it do
          is_expected.to contain_file('/etc/opendnssec/addns-test_addns.xml').with(
            owner: 'root',
            group: 'root'
          ).with_content(
            %r{
			<\?xml\sversion="1.0"\sencoding="UTF-8"\?>
			\s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
			\s+<Adapter>
			\s+<DNS>
			\s+<Inbound>
			\s+<RequestTransfer>
			\s+</RequestTransfer>
			\s+<AllowNotify>
			\s+</AllowNotify>
			\s+</Inbound>
			\s+<Outbound>
			\s+<ProvideTransfer>
			\s+</ProvideTransfer>
			\s+<Notify>
			\s+</Notify>
			\s+</Outbound>
			\s+</DNS>
			\s+</Adapter>
            }x
          )
        end
        it do
          is_expected.to contain_exec(
            'Forcing ods-ksmutil to update after modifying addns-test_addns.xml'
          ).with(
            command: '/usr/bin/yes | /usr/bin/ods-ksmutil update all',
            user: 'root',
            refreshonly: true,
            subscribe: 'File[/etc/opendnssec/addns-test_addns.xml]'
          )
        end
      end
      describe 'Change Defaults' do
        context 'masters' do
          before { params.merge!(masters: ['master']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/addns-test_addns.xml').with(
              owner: 'root',
              group: 'root'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter>
              \s+<DNS>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x
            )
          end
        end
        context 'provide_xfrs' do
          before { params.merge!(provide_xfrs: ['provide_xfr']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter>
              \s+<DNS>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x
            )
          end
        end
        context 'provide_xfrs and master' do
          before { params.merge!(provide_xfrs: ['provide_xfr'], masters: ['master']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter>
              \s+<DNS>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x
            )
          end
        end
        context 'opendnssec::user' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              user => 'foobar',
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_owner('foobar')
          end
          it do
            is_expected.to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_addns.xml'
            ).with_user('foobar')
          end
        end
        context 'opendnssec::group' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              group => 'foobar',
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_group('foobar')
          end
        end
        context 'opendnssec::manage_ods_ksmutil' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              manage_ods_ksmutil => false,
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_addns.xml'
            )
          end
        end
        context 'opendnssec::enabled' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              enabled => false,
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_addns.xml'
            )
          end
        end
        context 'opendnssec::remotes Tsig name' do
          before { params.merge!(provide_xfrs: ['provide_xfr'], masters: ['master']) }
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              policies => {'test_policy' => {} },
              tsigs => {
                'test_tsig_master' => { 'data' => 'AAAA', 'algo' => 'hmac-sha1' },
                'test_tsig_provide_xfr' => { 'data' => 'BBBB','algo' => 'hmac-md5' },
              },
              remotes  => {
                'master' => {
                  'address4' => '192.0.2.1',
                  'tsig_name' => 'test_tsig_master',
                },
                'provide_xfr' => {
                  'address4' => '192.0.2.2',
                  'tsig_name' => 'test_tsig_provide_xfr',
                },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter>
              \s+<DNS>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_master.xml"\s/>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_provide_xfr.xml"\s/>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x
            )
          end
        end
        context 'opendnssec::remotes default_tsig_name' do
          before { params.merge!(provide_xfrs: ['provide_xfr'], masters: ['master']) }
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              policies => {'test_policy' => {} },
              default_tsig_name => 'test_tsig_default',
              tsigs => {
                'test_tsig_default' => { 'data' => 'AAAA', 'algo' => 'hmac-sha1' },
                'test_tsig_provide_xfr' => { 'data' => 'BBBB','algo' => 'hmac-md5' },
              },
              remotes  => {
                'master' => {
                  'address4' => '192.0.2.1',
                },
                'provide_xfr' => {
                  'address4' => '192.0.2.2',
                  'tsig_name' => 'test_tsig_provide_xfr',
                },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter>
              \s+<DNS>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_default.xml"\s/>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_provide_xfr.xml"\s/>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x
            )
          end
        end
        context 'opendnssec::xferout_enabled' do
          before { params.merge!(provide_xfrs: ['provide_xfr']) }
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              xferout_enabled => false,
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter>
              \s+<DNS>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x
            )
          end
        end
      end
      describe 'check bad type' do
        context 'masters' do
          before { params.merge!(masters: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'provide_xfrs' do
          before { params.merge!(provide_xfrs: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
