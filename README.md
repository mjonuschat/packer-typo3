# TYPO3 Vagrant

This packer configuration creates a Ubuntu based VM for TYPO3 development,
primarily for PostgreSQL.

## Quick-start

### 1. Build the box
```sh
packer build boxes/typo3.json
vagrant box add --name mojocode/typo3 builds/typo3.box
```

### 2. Create a vagrant project

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = 'mojocode/typo3'
  config.vm.box_check_update = false

  config.vm.network 'forwarded_port', guest: 80, host: 8080

  config.vm.network 'private_network', ip: '192.168.144.120'

  config.vm.synced_folder 'Web', '/var/www'

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 2048
    vb.cpus   = 2
  end
end
```

### 3. Run the box
```sh
vagrant up
```

## Features

The example Vagrant file uses a private network with IP 192.168.144.120. The wildcard hostname
`*.local.typo3.org` is resolved to this IP address so you access the webserver in the virtual
machine with a nice hostname.

## Software
- Nginx 1.8.0
- PHP-FPM 5.5.9
- MariaDB 10.0
- PostgreSQL 9.4

## Credentials
MySQL
- User: vagrant
- Password: vagrant

PostgreSQL:
- User: vagrant
- Password: vagrant

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
