# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::tsig' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_tsig' }

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
      data: 'AAAA',
      # algo: "hmac-sha256",
      # key_name: :undef,
    }
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
        it do
          is_expected.to contain_file('/etc/opendnssec/tsigs/test_tsig.xml').with(
            ensure: 'file',
            owner: 'root',
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<TSIG>
            \s+<Name>test_tsig</Name>
            \s+<Algorithm>hmac-sha256</Algorithm>
            \s+<Secret>AAAA</Secret>
            \s+</TSIG>
            }x,
          )
        end
        it do
          is_expected.to contain_exec(
            'Forcing ods-ksmutil to update after modifying /etc/opendnssec/tsigs/test_tsig.xml',
          ).with(
            command: '/usr/bin/yes | /usr/bin/ods-ksmutil update all',
            user: 'root',
            refreshonly: true,
            subscribe: 'File[/etc/opendnssec/tsigs/test_tsig.xml]',
          )
        end
      end
      describe 'Change Defaults' do
        context 'key_name' do
          before(:each) { params.merge!(key_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/tsigs/foobar.xml').with(
              ensure: 'file',
              owner: 'root',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<TSIG>
              \s+<Name>foobar</Name>
              \s+<Algorithm>hmac-sha256</Algorithm>
              \s+<Secret>AAAA</Secret>
              \s+</TSIG>
              }x,
            )
          end
        end
      end
      describe 'check bad type' do
        context 'data' do
          before(:each) { params.merge!(data: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'algo' do
          before(:each) { params.merge!(algo: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'key_name' do
          before(:each) { params.merge!(key_name: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
