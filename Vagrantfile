# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  'vagrant-box'                     => 'ubuntu/trusty64',
  'package-manager'                 => 'apt',
  'storage-controller'              => 'SATAController',
  'message-broker-script'           => '/rabbitmq.sh',
  'database-script'                 => '/mariadb.sh',
  'identity-script'                 => '/keystone.sh',
  'image-script'                    => '/glance.sh',
  'compute-controller-script'       => '/nova-controller.sh',
  'compute-script'                  => '/nova-compute.sh',
  'dashboard-script'                => '/horizon.sh',
  'block-storage-controller-script' => '/cinder-controller.sh',
  'block-storage-script'            => '/cinder-storage.sh',
}

vd_conf = ENV.fetch('VD_CONF', 'etc/settings.yaml')
if File.exist?(vd_conf)
  require 'yaml'
  user_conf = YAML.load_file(vd_conf)
  conf.update(user_conf)
end


VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = conf['vagrant-box']
  config.vm.synced_folder "shared/", "/root/shared", create: true

  config.vm.define :message_broker do |message_broker|
    message_broker.vm.hostname = 'message-broker'
    message_broker.vm.network :private_network, ip: '192.168.50.10'
    message_broker.vm.network :forwarded_port, guest: 5672 , host: 5672 
    message_broker.vm.provision "shell", path: conf['package-manager'] + conf['message-broker-script']
  end

  config.vm.define :database do |database|
    database.vm.hostname = 'database'
    database.vm.network :private_network, ip: '192.168.50.11'
    database.vm.network :forwarded_port, guest: 3306, host: 3306
    database.vm.provision "shell", path: conf['package-manager'] + conf['database-script']
  end

  config.vm.define :identity do |identity|
    identity.vm.hostname = 'identity'
    identity.vm.network :private_network, ip: '192.168.50.12'
    identity.vm.network :forwarded_port, guest: 5000, host: 5000
    identity.vm.network :forwarded_port, guest: 35357, host: 35357
    identity.vm.provision "shell", path: conf['package-manager'] + conf['identity-script']
    #identity.vm.provision "shell", path: conf['package-manager'] + "/keystone_dev.sh"
  end

  config.vm.define :image do |image|
    image.vm.hostname = 'image'
    image.vm.network :private_network, ip: '192.168.50.13'
    image.vm.network :forwarded_port, guest: 9292, host: 9292
    image.vm.provision "shell", path: conf['package-manager'] + conf['image-script']
    #image.vm.provision "shell", path: conf['package-manager'] + "/glance_dev.sh"
  end

  config.vm.define :compute_controller do |compute_controller|
    compute_controller.vm.hostname = 'compute-controller'
    compute_controller.vm.network :private_network, ip: '192.168.50.14'
    compute_controller.vm.network :forwarded_port, guest: 8774, host: 8774
    compute_controller.vm.provision "shell", path: conf['package-manager'] + conf['compute-controller-script']
    compute_controller.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 2048]
    end
  end

  config.vm.define :compute do |compute|
    compute.vm.hostname = 'compute'
    compute.vm.network :private_network, ip: '192.168.50.15'
    compute.vm.provision "shell", path: conf['package-manager'] + conf['compute-script']
  end

  config.vm.define :dashboard do |dashboard|
    dashboard.vm.hostname = 'dashboard'
    dashboard.vm.network :private_network, ip: '192.168.50.17'
    dashboard.vm.network :forwarded_port, guest: 80, host: 8080
    dashboard.vm.provision "shell", path: conf['package-manager'] + conf['dashboard-script']
  end

  config.vm.define :block_storage_controller do |block_storage_controller|
    block_storage_controller.vm.hostname = 'block-storage-controller'
    block_storage_controller.vm.network :private_network, ip: '192.168.50.18'
    block_storage_controller.vm.network :forwarded_port, guest: 8776, host: 8776
    block_storage_controller.vm.provision "shell", path: conf['package-manager'] + conf['block-storage-controller-script']
  end

  config.vm.define :block_storage do |block_storage|
    block_storage.vm.hostname = 'block-storage'
    block_storage.vm.network :private_network, ip: '192.168.50.19'
    block_storage.vm.provision "shell", path: conf['package-manager'] + conf['block-storage-script']
    block_storage.vm.provider "virtualbox" do |v|
      file_to_disk='storage.vdi'
      v.customize ['createhd', '--filename', file_to_disk, '--size', 50 * 1024]
      v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
    end
  end

end
