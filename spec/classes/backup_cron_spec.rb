require 'spec_helper'

describe 'opendnssec::backup_cron' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'opendnssec::backup.example.com' }

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
      :backup_host => 'foobar.example.com',
      #:backup_user => 'backup',
      #:backup_glob => 'backup-20*.tar.bz2',
      #:retention => '500',
      #:backup_dir => '/opt/backup',
      #:script_path => '/usr/local/bin/backup-hsm-mysql.sh',

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
        it do
          is_expected.to contain_file('/usr/local/bin/backup-hsm-mysql.sh').with(
            ensure:  'file',
            mode:  '0755',
            owner:  'root',
            group:  'root',
          ).with_content(
            %r{NUMBER=500}
          ).with_content(
            %r{DIR="/opt/backup"}
          ).with_content(
            %r{FILESGLOB="backup-20\*\.tar\.bz2"}
          ).with_content(
            %r{BACKUP_HOST=foobar.example.com}
          ).with_content(
            %r{USER=="backup"}
          )
        end
        it do
          is_expected.to contain_cron('backup-hsm-mysql').with(
            ensure:  'present',
            command:  '/usr/local/bin/backup-hsm-mysql.sh',
            user:  'root',
            hour:  '*/6',
            minute:  '0',
            require:  'File[/usr/local/bin/backup-hsm-mysql.sh]',
          )
        end
      end
      describe 'Change Defaults' do
        context 'backup_host' do
          before { params.merge!(backup_host: 'backup.example.com') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh'
            ).with_content(
              %r{BACKUP_HOST=backup.example.com}
            )
          end
        end
        context 'backup_user' do
          before { params.merge!(backup_user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh'
            ).with_content(
              %r{USER=="foobar"}
            )
          end
        end
        context 'backup_glob' do
          before { params.merge!(backup_glob: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh'
            ).with_content(
              %r{FILESGLOB="foobar"}
            )
          end
        end
        context 'retention' do
          before { params.merge!(retention: 200) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh'
            ).with_content(
              %r{NUMBER=200}
            )
          end
        end
        context 'backup_dir' do
          before { params.merge!(backup_dir: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh'
            ).with_content(
              %r{DIR="/foobar"}
            )
          end
        end
        context 'script_path' do
          before { params.merge!(script_path: '/foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_file('/foobar') }
          it do
            is_expected.to contain_cron('backup-hsm-mysql').with(
              command: '/foobar',
              require: 'File[/foobar]'
            ) 
          end
        end
      end
      describe 'check bad type' do
        context 'ackup_host' do
          before { params.merge!(ackup_host: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'backup_user' do
          before { params.merge!(backup_user: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'backup_glob' do
          before { params.merge!(backup_glob: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'retention' do
          before { params.merge!(retention: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'backup_dir' do
          before { params.merge!(backup_dir: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'script_path' do
          before { params.merge!(script_path: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
