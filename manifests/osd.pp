define cephdeploy::osd(
){

  include cephdeploy
  $user = $::ceph_deploy_user
  $disk = $name

  file {"log $disk":
    owner => $user,
    group => $user,
    path  => "/home/$user/bootstrap/ceph.log",
  }

  exec { "get config $disk":
    cwd     => "/home/$user/bootstrap",
    user    => $user,
    command => "/usr/local/bin/ceph-deploy config push $::hostname",
    require => [ Exec['install ceph'], File["/etc/sudoers.d/$user"], File["log $disk"] ],
    unless  => "/usr/bin/test -e /etc/ceph/ceph.conf",
  }
    
  exec { "gatherkeys_$disk":
    cwd     => "/home/$user/bootstrap",
    user    => $user,
    command => "/usr/local/bin/ceph-deploy gatherkeys $::ceph_primary_mon",
    require => [ Exec['install ceph'], File["/etc/sudoers.d/$user"], File["log $disk"] ],
    unless  => "/usr/bin/test -e /home/$user/bootstrap/ceph.bootstrap-osd.keyring",
  }

  exec {"copy admin key $disk":
    command => "/bin/cp /home/$user/bootstrap/ceph.client.admin.keyring /etc/ceph",
    unless  => '/usr/bin/test -e /etc/ceph/ceph.client.admin.keyring',
    require => Exec["gatherkeys_$disk"],
  }

  exec { "zap $disk":
    cwd     => "/home/$user/bootstrap",
    command => "/usr/local/bin/ceph-deploy disk zap $::hostname:$disk",
    require => [ Exec['install ceph'], Exec["gatherkeys_$disk"] ],
    unless  => "/usr/bin/test -e /home/$user/zapped/$disk",
  }

  exec { "create osd $disk":
    cwd     => "/home/$user/bootstrap",
    command => "/usr/local/bin/ceph-deploy --overwrite-conf osd create $::hostname:$disk",
    require => Exec["zap $disk"],
    unless  => "/usr/bin/test -e /home/$user/zapped/$disk",
  }
  
  file { "/home/$user/zapped/$disk":
    ensure  => present,
    require => [ Exec["zap $disk"], Exec["create osd $disk"], File["/home/$user/zapped"] ],
  }



}
