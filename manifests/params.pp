#== Class: opendnssec::params
#
class opendnssec::params {
  case $facts['os']['family'] {
    'RedHat' : {
      $packages = ['opendnssec', 'libxslt']
      $services = ['ods-enforcerd', 'ods-signerd']
      $base_dir = '/var/opendnssec'
      $repository_module = '/usr/lib64/pkcs11/libsofthsm2.so'
      $sqlite_packages = []
      $mysql_packages = []
      $ksmutil_path = '/bin/ods-ksmutil'
      $enforcer_path = '/usr/sbin/ods-enforcer'
      $datastore_engine = 'sqlite'
      $group = 'ods'
    }
    'Debian': {
      case $facts['os']['release']['major'] {
        '14.04': {
          $repository_module = '/usr/lib/softhsm/libsofthsm.so'
        }
        default: {
          $repository_module = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so'
        }
      }
      $group = 'opendnssec'
      $datastore_engine = 'mysql'
      $packages = ['opendnssec', 'xsltproc']
      $services = ['opendnssec-enforcer', 'opendnssec-signer']
      $base_dir = '/var/lib/opendnssec'
      $sqlite_packages = ['opendnssec-enforcer-sqlite']
      $mysql_packages = ['opendnssec-enforcer-mysql']
      $ksmutil_path = '/usr/bin/ods-ksmutil'
      $enforcer_path = '/usr/sbin/ods-enforcer'
    }
    default: {
      $datastore_engine = 'mysql'
      $packages = ['opendnssec', 'xsltproc']
      $services = ['opendnssec-enforcer', 'opendnssec-signer']
      $base_dir = '/var/lib/opendnssec'
      $repository_module = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so'
      $sqlite_packages = ['opendnssec-enforcer-sqlite']
      $mysql_packages = ['opendnssec-enforcer-mysql']
      $ksmutil_path = '/usr/bin/ods-ksmutil'
      $enforcer_path = '/usr/sbin/ods-enforcer'
    }
  }

}
