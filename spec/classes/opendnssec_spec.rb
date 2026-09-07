# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec' do
  let(:node) { 'opendnssec.example.com' }
  let(:facts) { {} }
  let(:params) do
    {
      # :enabled => true,
      # :xferout_enabled => true,
      # :user => 'root',
      # :group => 'root',
      # :opendnssec_version => '1',
      # :manage_policies => true,
      # :policies => {},
      # :manage_zones => true,
      # :zones => {},
      # :manage_addns => true,
      # :addns_tsigs => {},
      # :addns_xfers_in => {},
      # :addns_xfers_out => {},
      # :logging_level => '3',
      # :logging_facility => 'loacl0',
      # :repository_name => 'SoftHSM',
      # :repository_module => '#{repository_module}',
      # :repository_pin => '1234',
      # :repository_capacity => :undef,
      # :repository_token_label => 'OpenDNSSEC',
      # :datastore_engine => 'mysql',
      # :datastore_host => 'localhost',
      # :datastore_port => '3306',
      # :datastore_name => 'kasp',
      # :datastore_user => 'opendnssec',
      # :datastore_password => 'change_me',
      # :listener_port => '53',
      # :policy_file => '/etc/opendnssec/kasp.xml',
      # :zone_file => '/etc/opendnssec/zonelist.xml',
      # :addns_file => '/etc/opendnssec/addns.xml',

    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      let(:repository_module) { '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so' }
      let(:packages) { %w[opendnssec xsltproc] }
      let(:services) { %w[opendnssec-enforcer opendnssec-signer] }
      let(:base_dir) { '/var/lib/opendnssec' }
      let(:sqlite_packages) { ['opendnssec-enforcer-sqlite'] }
      let(:mysql_packages) { ['opendnssec-enforcer-mysql'] }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('opendnssec') }
        it { is_expected.to contain_opendnssec__addns('default') }
        it { is_expected.to contain_opendnssec__policy('default') }
        it { is_expected.to contain_concat__fragment('policy_default') }

        it { is_expected.to contain_class('mysql::server') }

        it 'test packages' do
          (packages + mysql_packages).each do |package|
            is_expected.to contain_package(package)
          end
        end

        it do
          is_expected.to contain_file(base_dir).with(
            ensure: 'directory',
            mode: '0640',
            owner: 'root',
          )
        end

        it 'test services' do
          services.each do |service|
            is_expected.to contain_service(service).with(
              ensure: 'running',
              enable: true,
            )
          end
        end

        it do
          is_expected.to contain_file('/etc/opendnssec/conf.xml').with(
            ensure: 'file',
            mode: '0644',
            owner: 'root',
          ).with_content(
            %r{<Repository\s+name="SoftHSM">
            \s+<Module>#{repository_module}</Module>
            \s+<TokenLabel>OpenDNSSEC</TokenLabel>
            \s+<PIN>1234</PIN>
            \s+<SkipPublicKey/>
            \s+</Repository>
            }x,
          ).with_content(
            %r{<Verbosity>3</Verbosity>
            \s+<Syslog>
            \s+<Facility>local0</Facility>
            }x,
          ).with_content(
            %r{<PolicyFile>/etc/opendnssec/kasp.xml</PolicyFile>},
          ).with_content(
            %r{<ZoneListFile>/etc/opendnssec/zonelist.xml</ZoneListFile>},
          ).with_content(
            %r{<Privileges>
            \s+<User>root</User>
            \s+<Group>(opendnssec|ods)</Group>
            \s+</Privileges>
            }x,
          ).with_content(
            %r{
            <Listener>
            \s+<Interface>
            \s+<Port>53</Port>
            \s+</Interface>
            \s+</Listener>
            }x,
          )
        end

        if facts[:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_content(
              %r{
              <Datastore>
              \s+<SQLite>#{base_dir}/kasp.db</SQLite>
              \s+</Datastore>
              }x,
            )
          end
        else
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_content(
              %r{
              <Datastore>
              \s+<MySQL>
              \s+<Host\s+Port="3306">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              \s+</Datastore>
              }x,
            )
          end
        end
        it do
          is_expected.to contain_exec('updated conf.xml').with(
            command: '/usr/sbin/ods-enforcer update conf',
            user: 'root',
            refreshonly: true,
          )
        end

        it do
          is_expected.to contain_file('/etc/opendnssec/MASTER').with(
            ensure: 'file',
            mode: '0644',
            owner: 'root',
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
              '/etc/opendnssec/MASTER',
            ).with_ensure('absent')
          end

          it { is_expected.not_to contain_exec('updated conf.xml') }
        end

        context 'user' do
          before { params.merge!(user: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(base_dir).with_owner('foobar')
          end

          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_owner('foobar')
          end

          it do
            is_expected.to contain_exec(
              'updated conf.xml',
            ).with_user('foobar')
          end

          it do
            is_expected.to contain_file(
              '/etc/opendnssec/MASTER',
            ).with_owner('foobar')
          end
        end

        context 'group' do
          before { params.merge!(group: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(base_dir).with_group('foobar')
          end

          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_group('foobar')
          end

          it do
            is_expected.to contain_file('/etc/opendnssec/MASTER').with_group('foobar')
          end
        end

        context 'logging_level' do
          before { params.merge!(logging_level: 5) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Verbosity>5</Verbosity>
              \s+<Syslog>
              \s+<Facility>local0</Facility>
              }x,
            )
          end
        end

        context 'logging_facility' do
          before { params.merge!(logging_facility: 'cron') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Verbosity>3</Verbosity>
              \s+<Syslog>
              \s+<Facility>cron</Facility>
              }x,
            )
          end
        end

        context 'repository_name' do
          before { params.merge!(repository_name: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="foobar">
              \s+<Module>#{repository_module}</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>1234</PIN>
              \s+<SkipPublicKey/>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'repository_module' do
          before { params.merge!(repository_module: '/foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="SoftHSM">
              \s+<Module>/foobar</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>1234</PIN>
              \s+<SkipPublicKey/>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'repository_pin' do
          before { params.merge!(repository_pin: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="SoftHSM">
              \s+<Module>#{repository_module}</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>foobar</PIN>
              \s+<SkipPublicKey/>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'repository_capacity' do
          before { params.merge!(repository_capacity: 1) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="SoftHSM">
              \s+<Module>#{repository_module}</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>1234</PIN>
              \s+<Capacity>1</Capacity>
              \s+<SkipPublicKey/>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'repository_token_label' do
          before { params.merge!(repository_token_label: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="SoftHSM">
              \s+<Module>#{repository_module}</Module>
              \s+<TokenLabel>foobar</TokenLabel>
              \s+<PIN>1234</PIN>
              \s+<SkipPublicKey/>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'skip_publickey' do
          before { params.merge!(skip_publickey: false) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="SoftHSM">
              \s+<Module>#{repository_module}</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>1234</PIN>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'repository_capacity' do
          before { params.merge!(require_backup: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<Repository\s+name="SoftHSM">
              \s+<Module>#{repository_module}</Module>
              \s+<TokenLabel>OpenDNSSEC</TokenLabel>
              \s+<PIN>1234</PIN>
              \s+<RequireBackup/>
              \s+<SkipPublicKey/>
              \s+</Repository>
              }x,
            )
          end
        end

        context 'datastore_engine' do
          before { params.merge!(datastore_engine: 'sqlite') }

          it { is_expected.to compile }

          it 'test sql packages' do
            mysql_packages.each do |package|
              is_expected.not_to contain_package(package)
            end
            sqlite_packages.each do |package|
              is_expected.to contain_package(package)
            end
          end

          it { is_expected.not_to contain_mysql__db('kasp') }
        end

        context 'datastore_host' do
          before { params.merge!(datastore_host: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+Port="3306">foobar</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x,
            )
          end
        end

        context 'datastore_port' do
          before { params.merge!(datastore_port: 1337) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+Port="1337">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x,
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
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+Port="3306">localhost</Host>
              \s+<Database>foobar</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x,
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
            is_expected.to contain_file(
              '/etc/opendnssec/conf.xml',
            ).with_content(
              %r{<Datastore>
              \s+<MySQL>
              \s+<Host\s+Port="3306">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>foobar</Username>
              \s+<Password>change_me</Password>
              \s+</MySQL>
              }x,
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
              \s+<Host\s+Port="3306">localhost</Host>
              \s+<Database>kasp</Database>
              \s+<Username>opendnssec</Username>
              \s+<Password>foobar</Password>
              \s+</MySQL>
              }x,
            )
          end
        end

        context 'policy_file' do
          before { params.merge!(policy_file: '/foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<PolicyFile>/foobar</PolicyFile>},
            )
          end
        end

        context 'zone_file' do
          before { params.merge!(zone_file: '/foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{<ZoneListFile>/foobar</ZoneListFile>},
            )
          end
        end

        context 'listener_address' do
          before { params.merge!(listener_address: '192.0.2.1') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{
              <Listener>
              \s+<Interface>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Interface>
              \s+</Listener>
              }x,
            )
          end
        end

        context 'listener_port' do
          before { params.merge!(listener_port: 42) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{
              <Listener>
              \s+<Interface>
              \s+<Port>42</Port>
              \s+</Interface>
              \s+</Listener>
              }x,
            )
          end
        end

        context 'listener_address and port' do
          before do
            params.merge!(
              listener_address: '192.0.2.1',
              listener_port: 42,
            )
          end

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/etc/opendnssec/conf.xml').with_content(
              %r{
              <Listener>
              \s+<Interface>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>42</Port>
              \s+</Interface>
              \s+</Listener>
              }x,
            )
          end
        end
      end
    end
  end
end
