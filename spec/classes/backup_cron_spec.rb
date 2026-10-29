# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::backup_cron' do
  let(:node) { 'backup.example.com' }
  let(:facts) { {} }
  let(:params) do
    {
      backup_host: 'foobar.example.com',
      require_backup: true,
      # :backup_user => 'backup',
      # :backup_glob => '*.tar.bz2',
      # :date_format => '%Y%m%d-%H%M',
      # :retention => '500',
      # :backup_dir => '/opt/backup',
      # :tmp_dirbase => '/opt/tmp',
      # :script_path => '/usr/local/bin/backup-hsm-mysql.sh',
      # :require_backup => false,
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

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('opendnssec::backup_cron') }

        it do
          is_expected.to contain_file('/opt/backup').with(
            ensure: 'directory',
            owner:  'backup',
          )
        end

        it do
          is_expected.to contain_file('/opt/tmp').with(
            ensure: 'directory',
            owner:  'backup',
          )
        end

        it do
          is_expected.to contain_file('/usr/local/bin/backup-hsm-mysql.sh').with(
            ensure: 'file',
            mode: '0755',
            owner: 'backup',
          ).with_content(
            %r{NUMBER=500},
          ).with_content(
            %r{DIR="/opt/backup"},
          ).with_content(
            %r{TMP_DIR="\$\(mktemp -d --tmpdir=/opt/tmp\)"},
          ).with_content(
            %r{FILESGLOB="\*\.tar\.bz2"},
          ).with_content(
            %r{TODAY="\$\(date \+%Y%m%d-%H%M\)"},
          ).with_content(
            %r{BACKUP_HOST=foobar.example.com},
          ).with_content(
            %r{USER=="backup"},
          )
        end

        it do
          is_expected.to contain_cron('backup-hsm-mysql').with(
            ensure: 'present',
            command: '/usr/local/bin/backup-hsm-mysql.sh',
            user: 'root',
            hour: '*/6',
            minute: '0',
            require: 'File[/usr/local/bin/backup-hsm-mysql.sh]',
          )
        end
      end

      describe 'Change Defaults' do
        context 'backup_host' do
          before { params.merge!(backup_host: 'backup.example.com') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{BACKUP_HOST=backup.example.com},
            )
          end
        end

        context 'backup_user' do
          before { params.merge!(backup_user: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{USER=="foobar"},
            )
          end
        end

        context 'backup_glob' do
          before { params.merge!(backup_glob: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{FILESGLOB="foobar"},
            )
          end
        end

        context 'date_format' do
          before { params.merge!(date_format: 'foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{TODAY="\$\(date \+foobar\)"},
            )
          end
        end

        context 'retention' do
          before { params.merge!(retention: 200) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{NUMBER=200},
            )
          end
        end

        context 'backup_dir' do
          before { params.merge!(backup_dir: '/foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/foobar').with(
              ensure: 'directory',
              owner:  'backup',
            )
          end

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{DIR="/foobar"},
            )
          end
        end

        context 'tmp_dirbase' do
          before { params.merge!(tmp_dirbase: '/foobar') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_file('/foobar').with(
              ensure: 'directory',
              owner:  'backup',
            )
          end

          it do
            is_expected.to contain_file(
              '/usr/local/bin/backup-hsm-mysql.sh',
            ).with_content(
              %r{TMP_DIR="\$\(mktemp -d --tmpdir=/foobar\)"},
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
              require: 'File[/foobar]',
            )
          end
        end
      end
    end
  end
end
