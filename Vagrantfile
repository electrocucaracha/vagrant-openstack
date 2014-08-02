# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box     = 'precise64'
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
end