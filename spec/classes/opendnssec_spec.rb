require 'spec_helper'

describe 'opendnssec' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'opendnssec.example.com' }

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
      #:enabled => true,
      #:xferout_enabled => true,
      #:user => 'root',
      #:group => 'root',
      #:manage_packages => true,
      #:manage_datastore => true,
      #:manage_service => true,
      #:manage_ods_ksmutil => true,
      #:manage_conf => true,
      #:manage_policies => true,
      #:policies => {},
      #:manage_zones => true,
      #:zones => {},
      #:manage_addns => true,
      #:addns_tsigs => {},
      #:addns_xfers_in => {},
      #:addns_xfers_out => {},
      #:logging_level => '3',
      #:logging_facility => 'loacl0',
      #:repository_name => 'thales',
      #:repository_module => '/opt/nfast/toolkits/pkcs11/libcknfast.so',
      #:repository_pin => '11223344',
      #:repository_capacity => :undef,
      #:repository_token_label => 'OpenDNSSEC',
      #:datastore_engine => 'mysql',
      #:datastore_host => 'localhost',
      #:datastore_port => '3306',
      #:datastore_name => 'kasp',
      #:datastore_user => 'opendnssec',
      #:datastore_password => 'change_me',
      #:policy_file => '/etc/opendnssec/kasp.xml',
      #:zone_file => '/etc/opendnssec/zonelist.xml',
      #:addns_file => '/etc/opendnssec/addns.xml',

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context 'on #{os}' do
      let(:facts) do
        facts
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('opendnssec') }
        it { is_expected.to contain_package('opendnssec') }
        it { is_expected.to contain_package('opendnssec-enforcer-mysql') }
        it do
          is_expected.to contain_file('/var/lib/opendnssec').with(
            ensure: 'directory',
            mode: '0640',
            recurse: true,
            owner: 'root',
            group: 'root',
          )
        end
        it do
          is_expected.to contain_service('opendnssec-enforcer').with(
            ensure: 'running',
            enable: true,
          )
        end
        it do
          is_expected.to contain_service('opendnssec-signer').with(
            ensure: 'running',
            enable: true,
          )
        end
        it do
          is_expected.to contain_file('/etc/opendnssec/conf.xml').with(
            ensure: 'file',
            mode: '0644',
            owner: 'root',
            group: 'root',
          ).with_content(
            %r{<Repository\s+name="thales">
            \s+<Module>/opt/nfast/toolkits/pkcs11/libcknfast.so</Module>
            \s+<TokenLabel>OpenDNSSEC</TokenLabel>
            \s+<PIN>11223344</PIN>
            }x
          ).with_content(
            %r{<Verbosity>3</Verbosity>
            \s+<Syslog>
            \s+<Facility>loacl0</Facility>
            }x
          ).with_content(
            %r{<PolicyFile>/etc/opendnssec/kasp.xml</PolicyFile>}
          ).with_content(
            %r{<ZoneListFile>/etc/opendnssec/zonelist.xml</ZoneListFile>}
          ).with_content(
            %r{<Privileges>
            \s+<User>root</User>
            \s+<Group>root</Group>
            \s+</Privileges>
            }x
          ).with_content(
            %r{<Datastore>
            \s+<MySQL>
            \s+<Host\s+port="3306">localhost</Host>
            \s+<Database>kasp</Database>
            \s+<Username>opendnssec</Username>
            \s+<Password>change_me</Password>
            \s+</MySQL>
            }x
          )
        end
        it do
          is_expected.to contain_exec('ods-ksmutil updated conf.xml').with(
            command: '/usr/bin/ods-ksmutil update all',
            user: 'root',
            refreshonly: true,
            subscribe: 'File[/etc/opendnssec/conf.xml]',
          )
        end
        it do
          is_expected.to contain_file('/etc/opendnssec/MASTER').with(
            ensure: 'file',
            mode: '0644',
            owner: 'root',
            group: 'root',
          )
        end
        it do
          is_expected.to contain_mysql__db('kasp').with(
            user: 'opendnssec',
            password: 'change_me',
          )
        end
      end
      describe 'Change Defaults' do
        context 'enabled' do
          before { params.merge!(enabled: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/MASTER'
            ).with_ensure('absent')
          end
          it { is_expected.not_to contain_exec('ods-ksmutil updated conf.xml') }
        end
        context 'user' do
          before { params.merge!(user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/var/lib/opendnssec').with_owner('foobar')
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml'
            ).with_owner('foobar')
          end
          it do 
            is_expected.to contain_exec(
              'ods-ksmutil updated conf.xml'
            ).with_user('foobar')
          end
          it do
            is_expected.to contain_file('/etc/opendnssec/MASTER').with_owner('foobar')
          end
        end
        context 'group' do
          before { params.merge!(group: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/var/lib/opendnssec').with_group('foobar')
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml'
            ).with_group('foobar')
          end
          it do
            is_expected.to contain_file('/etc/opendnssec/MASTER').with_group('foobar')
          end
        end
        context 'manage_packages' do
          before { params.merge!(manage_packages: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_package('opendnssec') }
          it { is_expected.not_to contain_package('opendnssec-enforcer-mysql') }
        end
        context 'manage_datastore' do
          before { params.merge!(manage_datastore: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_package('opendnssec-enforcer-mysql') }
          it { is_expected.not_to contain_mysql__db('kasp') }
          it { is_expected.not_to contain_package('opendnssec-enforcer-sqlite') }
        end
        context 'manage_service' do
          before { params.merge!(manage_service: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_service('opendnssec-signer') }
          it { is_expected.not_to contain_service('opendnssec-enforcer') }
        end
        context 'manage_ods_ksmutil' do
          before { params.merge!(manage_ods_ksmutil: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_exec('ods-ksmutil updated conf.xml') }
        end
        context 'manage_conf' do
          before { params.merge!(manage_conf: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_file('/etc/opendnssec/conf.xml') }
        end
        context 'logging_level' do
          before { params.merge!(logging_level: 5) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Verbosity>5</Verbosity>
              \s+<Syslog>
              \s+<Facility>loacl0</Facility>
              }x
            )
          end
        end
        context 'logging_facility' do
          before { params.merge!(logging_facility: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Verbosity>3</Verbosity>
              \s+<Syslog>
              \s+<Facility>foobar</Facility>
              }x
            )
          end
        end
        context 'repository_name' do
          before { params.merge!(repository_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="foobar">
              \s+<Module>/opt/nfast/toolkits/pkcs11/libcknfast.so</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>11223344</PIN>
              }x
            )
          end
        end
        context 'repository_module' do
          before { params.merge!(repository_module: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="thales">
              \s+<Module>/foobar</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>11223344</PIN>
              }x
            )
          end
        end
        context 'repository_pin' do
          before { params.merge!(repository_pin: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="thales">
              \s+<Module>/opt/nfast/toolkits/pkcs11/libcknfast.so</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>foobar</PIN>
              }x
            )
          end
        end
        context 'repository_capacity' do
          before { params.merge!(repository_capacity: 1) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="thales">
              \s+<Module>/opt/nfast/toolkits/pkcs11/libcknfast.so</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>11223344</PIN>
              \s+<Capacity>1</Capacity>
              }x
            )
          end
        end
        context 'repository_token_label' do
          before { params.merge!(repository_token_label: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="thales">
              \s+<Module>/opt/nfast/toolkits/pkcs11/libcknfast.so</Module>
              \s+<TokenLabel>foobar</TokenLabel>
              \s+<PIN>11223344</PIN>
              }x
            )
          end
        end
        context 'datastore_engine' do
          before { params.merge!(datastore_engine: 'sqlite') }
          it { is_expected.to compile }
          it { is_expected.not_to contain_package('opendnssec-enforcer-mysql') }
          it { is_expected.not_to contain_mysql__db('kasp') }
          it { is_expected.to contain_package('opendnssec-enforcer-sqlite') }
        end
        context 'datastore_host' do
          before { params.merge!(datastore_host: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+port="3306">foobar</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x
            )
          end
        end
        context 'datastore_port' do
          before { params.merge!(datastore_port: 1337) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+port="1337">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x
            )
          end
        end
        context 'datastore_name' do
          before { params.merge!(datastore_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_mysql__db('foobar').with(
              user: 'opendnssec',
              password: 'change_me',
            )
          end
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+port="3306">localhost</Host>
              \s+<Database>foobar</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x
            )
          end
        end
        context 'datastore_user' do
          before { params.merge!(datastore_user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_mysql__db('kasp').with(
              user: 'foobar',
              password: 'change_me',
            )
          end
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+port="3306">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>foobar</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x
            )
          end
        end
        context 'datastore_password' do
          before { params.merge!(datastore_password: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_mysql__db('kasp').with(
              user: 'opendnssec',
              password: 'foobar',
            )
          end
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+port="3306">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>foobar</Password>
              \s+</MySQL>
              }x
            )
          end
        end
        context 'policy_file' do
          before { params.merge!(policy_file: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<PolicyFile>/foobar</PolicyFile>}
            )
          end
        end
        context 'zone_file' do
          before { params.merge!(zone_file: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<ZoneListFile>/foobar</ZoneListFile>}
            )
          end
        end
      end
      describe 'check bad type' do
        context 'enabled' do
          before { params.merge!(enabled: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'xferout_enabled' do
          before { params.merge!(xferout_enabled: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'user' do
          before { params.merge!(user: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'group' do
          before { params.merge!(group: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_packages' do
          before { params.merge!(manage_packages: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_datastore' do
          before { params.merge!(manage_datastore: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_service' do
          before { params.merge!(manage_service: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_ods_ksmutil' do
          before { params.merge!(manage_ods_ksmutil: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_conf' do
          before { params.merge!(manage_conf: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_policies' do
          before { params.merge!(manage_policies: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'policies' do
          before { params.merge!(policies: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_zones' do
          before { params.merge!(manage_zones: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          before { params.merge!(zones: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'manage_addns' do
          before { params.merge!(manage_addns: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'addns_tsigs' do
          before { params.merge!(addns_tsigs: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'addns_xfers_in' do
          before { params.merge!(addns_xfers_in: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'addns_xfers_out' do
          before { params.merge!(addns_xfers_out: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logging_level' do
          before { params.merge!(logging_level: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'logging_facility' do
          before { params.merge!(logging_facility: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'repository_name' do
          before { params.merge!(repository_name: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'repository_module' do
          before { params.merge!(repository_module: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'repository_pin' do
          before { params.merge!(repository_pin: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'repository_capacity' do
          before { params.merge!(repository_capacity: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'repository_token_label' do
          before { params.merge!(repository_token_label: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'datastore_engine' do
          before { params.merge!(datastore_engine: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'datastore_host' do
          before { params.merge!(datastore_host: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'datastore_port' do
          before { params.merge!(datastore_port: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'datastore_name' do
          before { params.merge!(datastore_name: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'datastore_user' do
          before { params.merge!(datastore_user: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'datastore_password' do
          before { params.merge!(datastore_password: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'policy_file' do
          before { params.merge!(policy_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zone_file' do
          before { params.merge!(zone_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'addns_file' do
          before { params.merge!(addns_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
