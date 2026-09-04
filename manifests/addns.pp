# @summary Add a new addns configuration
# @param masters Array of masters to add
# @param provide_xfrs Array of masters to provide xfrs to
#
define opendnssec::addns (
  Array[String] $masters      = [],
  Array[String] $provide_xfrs = [],
) {
  include opendnssec
  $xsl_file           = $opendnssec::xsl_file
  $user               = $opendnssec::user
  $group              = $opendnssec::group
  $enabled            = $opendnssec::enabled
  $remotes            = $opendnssec::remotes
  $services           = $opendnssec::services

  $masters.each |String $master| {
    unless $master in $remotes {
      fail("addns-${name}: master (${master}) doesn't exist")
    }
  }
  $provide_xfrs.each |String $provide_xfr| {
    unless $provide_xfr in $remotes {
      fail("addns-${name}: provide_xfr (${provide_xfr}) doesn't exist")
    }
  }

  file { "/etc/opendnssec/addns-${name}.xml.tmp":
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/addns.xml.erb'),
    notify  => Exec["write /etc/opendnssec/addns-${name}.xml"],
  }
  exec { "write /etc/opendnssec/addns-${name}.xml":
    command     => "/usr/bin/xsltproc --xinclude ${xsl_file} /etc/opendnssec/addns-${name}.xml.tmp | sed 's/\sxml:base[^>]*//g' > /etc/opendnssec/addns-${name}.xml",
    refreshonly => true,
    notify      => Service[$services],
  }
}
