#import 'weak'
#import 'strong'

//Specifying the modules to include as well as the Setting Selinux type to mls
node '<CONFIDENTIAL>_default' {
  $use_ldap = true
  $weak_categories = 'c0.c8143'
  $strong_categories = 'c0.c16383'
  $setype = 'mls'
  $webapp_name = '<CONFIDENTIAL>'

  include <CONFIDENTIAL>
  include restorecond
  include <CONFIDENTIAL>::ipsec_tunnels
  include selinux::checkselinux

  class { 'puppet::client' :
    server       => 'spacewalk.stone.strong',
    storeconfigs => true,
    use_daemon   => false,
  }
//Creating the etc/hosts file that will be destributed to all nodes
  host { 'idm.stone.strong':  ip => '*.*.*.*', }
  host { 'spacewalk.stone.weak':  ip => '*.*.*.*', }
  host { 'spacewalk.stone.strong': ip => '*.*.*.*', }
  host { 'rhim.stone.strong':      ip => '*.*.*.*', }
  host { 'logrhythm.stone.weak':  ip => '*.*.*.*' }
  host { '<CONFIDENTIAL>-db.stone.strong':     ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-db-data.stone.strong':     ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-fs.stone.strong':     ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-fs-data.stone.strong':     ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-web1.stone.strong':   ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-web1-data.stone.strong':   ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-app.stone.strong':    ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-app-data.stone.strong':    ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-web2.stone.strong':   ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>-web2-data.stone.strong':   ip => '*.*.*.*', }
  host { '<CONFIDENTIAL>.stone.strong':        ip => '*.*.*.*', }

  class { 'rsyslog::client' :
    server  => 'logrhythm.stone.strong',
    port    => '514',
    use_tls => false,
  }
}

//Setting Selinux to permissive mode by default for testing purposes. 
node '<CONFIDENTIAL>_<CONFIDENTIAL>' inherits <CONFIDENTIAL>_default {
  class { 'selinux' :
    enforcing => 'permissive',
    confined  => true,
    type      => 'mls'
  }
  #$webapp_name = '<CONFIDENTIAL>'

  file { '/etc/pki/ca-trust/source/anchors/ca-root-stone.strong.pem' :
    source => 'puppet:///modules/<CONFIDENTIAL>/ca-root-stone.strong.pem',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  file { '/etc/pki/ca-trust/source/anchors/ca-sub-stone.strong.pem' :
    source => 'puppet:///modules/<CONFIDENTIAL>/ca-sub-stone.strong.pem',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  file { '/etc/pki/ca-trust/source/anchors/ca-root-stone.weak.pem' :
    source => 'puppet:///modules/<CONFIDENTIAL>/ca-root-stone.weak.pem',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
  file { '/etc/pki/ca-trust/source/anchors/ca-sub-stone.weak.pem' :
    source => 'puppet:///modules/<CONFIDENTIAL>/ca-sub-stone.weak.pem',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

    firewall { '901 alweak all INPUT' :
    proto  => 'all',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '901 alweak all OUTPUT' :
    proto  => 'all',
    action => 'accept',
    chain  => 'OUTPUT',
  }

  <CONFIDENTIAL>::fw_rule { ' all weak ssh connections from strong spacewalk' :
    require_ipsec => false,
    port          => ['22'],
    proto         => 'tcp',
    iface         => 'eth0',
    subnet        => '*.*.*.*'
  }
  <CONFIDENTIAL>::fw_rule { '100 alweak tcp connections to db' :
    require_ipsec => false,
    port          => ['443', '8140'],
    proto         => 'tcp',
    iface         => 'eth0',
    subnet        => '*.*.*.*'
  }
  
  //Commented out firewall rules for testing purposes
#  <CONFIDENTIAL>::fw_rule { '101 alweak log aggregation' :
#    require_ipsec => false,
#    port          => ['514'],
#    proto         => 'tcp', 
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }
#  <CONFIDENTIAL>::fw_rule { '102 alweak spacewalk connections' :
#    require_ipsec => false,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }

################################################################################
# REMOVE ME AFTER CONFIGURATION
################################################################################
#  <CONFIDENTIAL>::fw_rule { '201 alweak spacewalk connections' :
#    require_ipsec => false,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'em1',
#    subnet        => '*.*.*.*'
#  }
}
node '<CONFIDENTIAL>_strong' inherits <CONFIDENTIAL>_<CONFIDENTIAL> {
  include <CONFIDENTIAL>::ipsec::fqdn_based::strong

  $dbHost = '<CONFIDENTIAL>-db.stone.strong'
  $db_host = '<CONFIDENTIAL>-db.stone.strong'


  #  include ntp_<CONFIDENTIAL>::utbstrong # basic NTP module connecting <CONFIDENTIAL> UTB servers to NTP server L100.0.9

#  <CONFIDENTIAL>::fw_rule { '152 alweak udp connections for NTP' :
#    require_ipsec => false,
#    port          => ['123'],
#    proto         => 'udp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule { '102 alweak RHIM UDP for kerberos' :
#    require_ipsec => false,
#    port          => ['88', '464'],
#    proto         => 'udp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule { '102 alweak RHIM TCP for kerberos' :
#    require_ipsec => false,
#    port          => ['88', '464'],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule {'102 alweak RHIM TCP for LDAP' :
#    require_ipsec => false,
#    port          => ['389'],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }
}

node '<CONFIDENTIAL>_strong_web' inherits <CONFIDENTIAL>_strong {
  $web_cluster_interface = 'eth1'
  $web_lan_interface     = 'eth3'
  $db_host               = '<CONFIDENTIAL>-db.stone.strong'

#  <CONFIDENTIAL>::fw_rule { '150 alweak tcp connections to db' :
#    require_ipsec => true,
#    port          => ['1521', '5671'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*'
#  }
#  <CONFIDENTIAL>::fw_rule { '151 alweak tcp connections to fs' :
#    require_ipsec => true,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*'
#  }
  file { '/etc/tomcat6/keystores/wss-truststore-keystore' :
    source => 'puppet:///modules/<CONFIDENTIAL>/wss-truststore-keystore',
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }
  file { '/etc/tomcat6/tnsadmin/cwallet.sso' :
    source => 'puppet:///modules/<CONFIDENTIAL>/cwallet.sso',
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }
  file { '/etc/tomcat6/tnsadmin/ewallet.p12' :
    source => 'puppet:///modules/<CONFIDENTIAL>/ewallet.p12',
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }
  file { '/etc/tomcat6/verifier.conf' :
    source => 'puppet:///modules/<CONFIDENTIAL>/verifier.conf',
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }

  tomcat::tnsentry { 'SERVICE-4154.SERVICE' :
    service_db => $dbHost,
    sid        => '<CONFIDENTIAL>',
    port       => '1521',
    comment    => 'Specific to UTB.',
  }
}

//Setting up node configuration (configuring specific servers to do specific things)
node '<CONFIDENTIAL>-web1' inherits '<CONFIDENTIAL>_strong_web' {
  $httpd_servername = '<CONFIDENTIAL>.stone.strong'
  class { '<CONFIDENTIAL>::webstrong' :
    client_interface  => 'eth3',
    data_interface    => 'eth1',
    shared_ipaddress  => '*.*.*.*',
    serveraliases     => [ '<CONFIDENTIAL>.stone.strong' ]
  }

  concat::fragment { 'tomcat-groupas-fragment' :
    target  => "${::tomcat::base}/${::tomcat::conf_file}",
    order   => '12',
    content => "
export SIS_GROUPAS_PRODUCER_WS_KEYSTORE=/etc/tomcat6/keystores/<CONFIDENTIAL>.groupas-keystore
export SIS_GROUPAS_PRODUCER_WS_KEYSTORE_ALIAS=<CONFIDENTIAL>.groupas
export SIS_PRODUCER_WS_KEYSTORE_PASS=changeit
export SIS_PRODUCER_WS_TRUSTSTORE=/etc/tomcat6/keystores/wss-truststore-keystore
export SIS_PRODUCER_WS_TRUSTSTORE_PASS=changeit
"
  }

#  <CONFIDENTIAL>::fw_rule { '102 alweak qpid connections from <CONFIDENTIAL>' :
#    require_ipsec => false,
#    port          => [5671],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*',
#  }
#
#  <CONFIDENTIAL>::fw_rule { '160 alweak tcp connections to strong-app' :
#    require_ipsec => true,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule { '160 alweak tcp connections to idm' :
#    require_ipsec => false,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }

  file { '/etc/tomcat6/<CONFIDENTIAL>.conf' :
    content => template("<CONFIDENTIAL>/<CONFIDENTIAL>.conf.erb"),
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }

}

node '<CONFIDENTIAL>-web2' inherits '<CONFIDENTIAL>_strong_web' {
  $httpd_servername = '<CONFIDENTIAL>.stone.strong'
  class { '<CONFIDENTIAL>::webstrong' :
    client_interface  => 'eth3',
    data_interface    => 'eth1',
    shared_ipaddress  => '*.*.*.*',
    serveraliases     => [ '<CONFIDENTIAL>.stone.strong' ]
  }

  concat::fragment { 'tomcat-groupas-fragment' :
    target  => "${::tomcat::base}/${::tomcat::conf_file}",
    order   => '12',
    content => "
export SIS_GROUPAS_PRODUCER_WS_KEYSTORE=/etc/tomcat6/keystores/<CONFIDENTIAL>.groupas-keystore
export SIS_GROUPAS_PRODUCER_WS_KEYSTORE_ALIAS=<CONFIDENTIAL>.groupas
export SIS_PRODUCER_WS_KEYSTORE_PASS=changeit
export SIS_PRODUCER_WS_TRUSTSTORE=/etc/tomcat6/keystores/wss-truststore-keystore
export SIS_PRODUCER_WS_TRUSTSTORE_PASS=changeit
"
  }

#  <CONFIDENTIAL>::fw_rule { '102 alweak qpid connections from <CONFIDENTIAL>' :
#    require_ipsec => false,
#    port          => [5671],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*/24',
#  }
#
#  <CONFIDENTIAL>::fw_rule { '160 alweak tcp connections to strong-app' :
#    require_ipsec => true,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule { '160 alweak tcp connections to idm' :
#    require_ipsec => false,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth0',
#    subnet        => '*.*.*.*'
#  }

  file { '/etc/tomcat6/<CONFIDENTIAL>.conf' :
    content => template("<CONFIDENTIAL>/<CONFIDENTIAL>.conf.erb"),
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }

}

node '<CONFIDENTIAL>-app' inherits '<CONFIDENTIAL>_strong_web' {
  include tomcat::abbyy
  include clamd

  $abbyy_serial = 'FXCX-9013-0000-5301-4571'
  $overriding_application_list = ['bookworm', 'verifier']

  class { '<CONFIDENTIAL>::appstrong' :
    data_interface   => 'eth1',
    serveraliases    => [ '<CONFIDENTIAL>-app.stone.strong' ]
  }

#  <CONFIDENTIAL>::fw_rule { '160 alweak tcp connections from strong-web1' :
#    require_ipsec => true,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule { '160 alweak tcp connections from strong-web2' :
#    require_ipsec => true,
#    port          => ['443'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*'
#  }
#
#  <CONFIDENTIAL>::fw_rule {'160 alweak tcp connections from db Purifile' :
#    require_ipsec => true,
#    port          => ['8888'],
#    proto         => 'tcp',
#    iface         => 'eth1',
#    subnet        => '*.*.*.*',
#  }
//POPULATING AND SETTING PERMISSIONS FOR FILES
  file { '/etc/tomcat6/bookworm.conf' :
    content => template("<CONFIDENTIAL (THE MODULE being used)>/bookworm.conf.erb"),
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }

  file { '/etc/tomcat6/verifier-node.conf' :
    content => template("<CONFIDENTIAL(THE MODULE being used)>/verifier-node.conf.erb"),
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }

  file { '/etc/tomcat6/indexer.conf' :
    content => template("<CONFIDENTIAL>/indexer.conf.erb"),
    owner  => 'tomcat',
    group  => 'tomcat',
    mode   => '0640',
  }

  file { '/etc/purifile/Purifile_policy_<CONFIDENTIAL>.xml' :
    source => 'puppet:///modules/<CONFIDENTIAL>/Purifile_policy_<CONFIDENTIAL>.xml',
    owner  => 'purifile',
    group  => 'purifile',
    mode   => '0640',
  }
}

node '<CONFIDENTIAL>-db' inherits '<CONFIDENTIAL>_strong' {
  include <CONFIDENTIAL>::ipsec::fqdn_based::weak

  # Most DB systems do not use mls, netlabel required as we use mls
  include netlabel
  class { 'netlabel::unlbl' :
    default_label => 'system_u:object_r:netlabel_peer_t:s0'
  }

  class { '<CONFIDENTIAL>::db' :
    data_interfaces => 'eth1',
  }

  class { 'netapp' :
    netapp_user  => 'scriptuser',
    script_owner => 'oracle',
  }

#  <CONFIDENTIAL>::fw_rule { '200 alweak tcp connections to db Netapp ssh' :
#    require_ipsec => false,
#    port          => ['22'],
#    proto         => 'tcp',
#    iface         => 'eth2',
#    subnet        => '*.*.*.*',
#  }
#
#  <CONFIDENTIAL>::fw_rule { '200 alweak tcp connections to fs Netapp ssh' :
#    require_ipsec => false,
#    port          => ['22'],
#    proto         => 'tcp',
#    iface         => 'eth2',
#    subnet        => '*.*.*.*',
#  }
#
#  <CONFIDENTIAL>::fw_rule { '200 alweak tcp connections to Netapp NFS' :
#    require_ipsec => false,
#    port          => ['111', '2049'],
#    proto         => 'tcp',
#    iface         => 'eth2',
#    subnet        => '*.*.*.*',
#  }
#
#  <CONFIDENTIAL>::fw_rule { '200 alweak udp connections to Netapp NFS' :
#    require_ipsec => false,
#    port          => ['111', '4046'],
#    proto         => 'udp',
#    iface         => 'eth2',
#    subnet        => '*.*.*.*',
#  }
#  <CONFIDENTIAL>::fw_rule { '200 alweak tcp connections to Netapp iSCSI' :
#    require_ipsec => false,
#    port          => ['3260', '2049'],
#    proto         => 'tcp',
#    iface         => 'eth2',
#    subnet        => '*.*.*.*',
#  }

#  <CONFIDENTIAL>::fw_rule { '200 alweak tcp connections to strong-app Purifile' :
#    require_ipsec => true,
#port          => ['8888'],
    #  proto         => 'tcp',
    #    iface         => 'eth1',
    #   subnet        => '*.*.*.*',
    #}

  # ## Define firewall rules to alweak access to puppet
  #  firewall { '100 alweak tcp connection in puppet' :
  #    chain     => 'CHECK_IPSEC_IN',
  #   action    => 'accept',
  #   port      =>  [ '443' , '8140' ],
  #    proto     => 'tcp',
  #    destination    => '*.*.*.*',
  #    iniface  => 'eth0'
  #}
  #firewall { '100 alweak tcp connection out puppet' :
  #    chain     => 'CHECK_IPSEC_IN',
  #    action    => 'accept',
  #    port      => [ '443' , '8140' ],
  #    proto     => 'tcp',
  #    source    => '*.*.*.*',
  #    outiface   => 'eth0'
  #}
}

node '<CONFIDENTIAL>-fs' inherits '<CONFIDENTIAL>_strong' {
  include <CONFIDENTIAL>::ipsec::fqdn_based::weak

  class { '<CONFIDENTIAL>::fs' :
    data_interfaces => [ 'eth1' ],
    data_levels     => {
    '*.*.*.*' => { level       => "s0-s8:${weak_categories}",
                           proxy_name => 'fs.weak' },
    '*.*.*.*' => { level       => "s0-s15:${strong_categories}",
                           proxy_name => 'fs.strong' },
    }
  }
  #<CONFIDENTIAL>::fw_rule { '200 alweak tcp connections to Netapp iSCSI' :
  #  require_ipsec => false,
  #  port          => ['3260'],
  #  proto         => 'tcp',
  #  iface         => 'eth2',
  #  subnet        => '*.*.*.*',
  #}
}
