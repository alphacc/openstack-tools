  $cinder_backend = hiera(cinder_backend, "Error no cinder backend defined")
  if( $cinder_backend == 'ceph' ) {

    package { ['librbd1']:
      ensure => present,
      }
    # If using qemu-kvm-rhev
    file { '/usr/lib64/qemu/librbd.so.1':
      ensure => link,
      target => '/usr/lib64/librbd.so.1',
      }
    file { 'ceph-directory':
      ensure  => directory,
      path    => '/etc/ceph/',
      mode    => 660,
      }
    file { 'ceph.conf':
      path    => '/etc/ceph/ceph.conf',
      source  => 'puppet:///modules/openstack/ceph.conf',
      mode    => 660,
      require => File['ceph-directory'],
      }
    file { 'update_virsh_secret.sh':
      path    => '/etc/ceph/update_virsh_secret.sh',
      source  => 'puppet:///modules/openstack/update_virsh_secret.sh',
      mode    => 700,
      require => File['ceph-directory'],
      }

    #grab the key
    $host=hiera(cinder_keymaster_host)
    $dir=hiera(cinder_keymaster_dir)
    $cinder_username=hiera(cinder_username)

    # Securely transfer the keys, may be replace by a kerberos stash when implemented.
    $cmd1="rsync -v -rlptD  -e 'ssh -i .ssh/id_dsa' nova@${host}:${dir}/ceph.client.${cinder_username}*keyring /etc/ceph/"
    exec { "retrieve_key_with_rsync":
      command => $cmd1,
      path    => "/usr/bin/:/bin/",
      require => File['ceph-directory'],
    } ->
    file { "/etc/ceph/ceph.client.${cinder_username}.keyring":
      audit => content,
      checksum => md5,
      notify => Exec[set_libvirt_secret],
    }

    $key=hiera(cinder_secret_uuid)
    $localdir='/etc/ceph'
    $cmd2="update_virsh_secret.sh -k $key -u $cinder_username -d $localdir"
    exec { "set_libvirt_secret":
      command => $cmd2,
      path    => "/usr/bin/:/bin/:/etc/ceph/",
      require => File['update_virsh_secret.sh'],
      refreshonly => true,
    }
  }

