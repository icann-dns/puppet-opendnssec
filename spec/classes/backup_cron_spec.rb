# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::backup_cron' do
  let(:node) { 'opendnssec::backup.example.com' }
  let(:facts) { {} }
  let(:params) do
    {
      backup_host: 'foobar.example.com',
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
            ensure:  'directory',
            owner:  'root',
          )
        end
        it do
          is_expected.to contain_file('/opt/tmp').with(
            ensure:  'directory',
            owner:  'root',
          )
        end
        if facts[:os]['family'] != 'RedHat'
          it do
            is_expected.to contain_file('/usr/local/bin/backup-hsm-mysql.sh').with(
              ensure:  'file',
              mode:  '0755',
              owner:  'root',
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
              ensure:  'present',
              command:  '/usr/local/bin/backup-hsm-mysql.sh',
              user:  'root',
              hour:  '*/6',
              minute:  '0',
              require:  'File[/usr/local/bin/backup-hsm-mysql.sh]',
            )
          end
        end
      end
      describe 'Change Defaults' do
        context 'backup_host' do
          before(:each) { params.merge!(backup_host: 'backup.example.com') }
          if facts[:os]['family'] != 'RedHat'
            it { is_expected.to compile }
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{BACKUP_HOST=backup.example.com},
              )
            end
          end
        end
        context 'backup_user' do
          before(:each) { params.merge!(backup_user: 'foobar') }
          it { is_expected.to compile }
          if facts[:os]['family'] != 'RedHat'
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{USER=="foobar"},
              )
            end
          end
        end
        context 'backup_glob' do
          before(:each) { params.merge!(backup_glob: 'foobar') }
          if facts[:os]['family'] != 'RedHat'
            it { is_expected.to compile }
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{FILESGLOB="foobar"},
              )
            end
          end
        end
        context 'date_format' do
          before(:each) { params.merge!(date_format: 'foobar') }
          if facts[:os]['family'] != 'RedHat'
            it { is_expected.to compile }
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{TODAY="\$\(date \+foobar\)"},
              )
            end
          end
        end
        context 'retention' do
          before(:each) { params.merge!(retention: 200) }
          if facts[:os]['family'] != 'RedHat'
            it { is_expected.to compile }
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{NUMBER=200},
              )
            end
          end
        end
        context 'backup_dir' do
          before(:each) { params.merge!(backup_dir: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/foobar').with(
              ensure:  'directory',
              owner:  'root',
            )
          end
          if facts[:os]['family'] != 'RedHat'
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{DIR="/foobar"},
              )
            end
          end
        end
        context 'tmp_dirbase' do
          before(:each) { params.merge!(tmp_dirbase: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/foobar').with(
              ensure:  'directory',
              owner:  'root',
            )
          end
          if facts[:os]['family'] != 'RedHat'
            it do
              is_expected.to contain_file(
                '/usr/local/bin/backup-hsm-mysql.sh',
              ).with_content(
                %r{TMP_DIR="\$\(mktemp -d --tmpdir=/foobar\)"},
              )
            end
          end
        end
        context 'script_path' do
          before(:each) { params.merge!(script_path: '/foobar') }
          if facts[:os]['family'] != 'RedHat'
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
      describe 'check bad type' do
        context 'backup_host' do
          before(:each) { params.merge!(backup_host: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'backup_user' do
          before(:each) { params.merge!(backup_user: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'backup_glob' do
          before(:each) { params.merge!(backup_glob: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'retention' do
          before(:each) { params.merge!(retention: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'backup_dir' do
          before(:each) { params.merge!(backup_dir: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'script_path' do
          before(:each) { params.merge!(script_path: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
