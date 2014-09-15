# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  config.vm.define :rabbitmq do |rabbitmq|
    rabbitmq.vm.hostname = 'rabbitmq-precise64'
    rabbitmq.vm.network :private_network, ip: '192.168.50.10'
    rabbitmq.vm.network :forwarded_port, guest: 5672 , host: 5672 
    rabbitmq.vm.provision "shell", path: "rabbitmq.sh"
  end

  config.vm.define :mysql do |mysql|
    mysql.vm.hostname = 'mysql-precise64'
    mysql.vm.network :private_network, ip: '192.168.50.11'
    mysql.vm.network :forwarded_port, guest: 3306, host: 3306
    mysql.vm.provision "shell", path: "mysql.sh"
  end

  config.vm.define :keystone do |keystone|
    keystone.vm.hostname = 'keystone-precise64'
    keystone.vm.network :private_network, ip: '192.168.50.12'
    keystone.vm.network :forwarded_port, guest: 5000, host: 5000
    keystone.vm.network :forwarded_port, guest: 35357, host: 35357
    #keystone.vm.provision "shell", path: "keystone.sh"
    keystone.vm.provision "shell", path: "keystone_dev.sh"
  end

  config.vm.define :glance do |glance|
    glance.vm.hostname = 'glance-precise64'
    glance.vm.network :private_network, ip: '192.168.50.13'
    glance.vm.network :forwarded_port, guest: 9292, host: 9292
    #glance.vm.provision "shell", path: "glance.sh"
    glance.vm.provision "shell", path: "glance_dev.sh"
  end

end
