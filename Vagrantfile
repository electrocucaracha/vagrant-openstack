# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  'deployment-style'                => 'all-in-one',
#  'deployment-style'                => 'group',
#  'deployment-style'                => 'microservices',
#  'deployment-style'                => 'containerize',
  'vagrant-box'                     => 'ubuntu/trusty64',
  'package-manager'                 => 'apt',
  'storage-controller'              => 'SATAController',
  'message-broker-script'           => '/rabbitmq.sh',
  'database-script'                 => '/mariadb.sh',
  'identity-script'                 => '/keystone.sh',
  'image-script'                    => '/glance.sh',
  'compute-controller-script'       => '/nova-controller.sh',
  'compute-script'                  => '/nova-compute.sh',
  'network-controller-script'       => '/neutron-controller.sh',
  'dashboard-script'                => '/horizon.sh',
  'block-storage-controller-script' => '/cinder-controller.sh',
  'block-storage-script'            => '/cinder-storage.sh',
  'nosql-database-script'           => '/mongodb.sh',
  'telemetry-controller-script'     => '/ceilometer-controller.sh',
  'supporting-services-script'      => '/supporting-services.sh',
  'controller-services-script'      => '/controller-services.sh',
  'compute-services-script'         => '/compute-services.sh',
  'block-storage-services-script'   => '/block-storage-services.sh',
  'all-in-one-script'               => '/all-in-one-services.sh',
  'container-script'                => '/kolla.sh',
  'enable-rally'                    => 'false'
}

block_file_to_disk='block-storage.vdi'
object_file_to_disk='object-storage.vdi'

vd_conf = ENV.fetch('VD_CONF', 'etc/settings.yaml')
if File.exist?(vd_conf)
  require 'yaml'
  user_conf = YAML.load_file(vd_conf)
  conf.update(user_conf)
end

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = conf['vagrant-box']
  config.vm.synced_folder "shared/", "/root/shared/", create: true
  config.vm.synced_folder conf['package-manager'] , "/root/scripts/", create: true

  case conf['deployment-style']
  when 'all-in-one'

    config.vm.define :all_in_one do |all_in_one|
      all_in_one.vm.hostname = 'all-in-one'
      all_in_one.vm.network :private_network, ip: '192.168.50.2'
      all_in_one.vm.network :forwarded_port, guest: 5672, host: 5672 
      all_in_one.vm.network :forwarded_port, guest: 15672, host: 15672 
      all_in_one.vm.network :forwarded_port, guest: 3306, host: 3306
      all_in_one.vm.network :forwarded_port, guest: 27017, host: 27017
      all_in_one.vm.network :forwarded_port, guest: 5000, host: 5000
      all_in_one.vm.network :forwarded_port, guest: 35357, host: 35357
      all_in_one.vm.network :forwarded_port, guest: 9292, host: 9292
      all_in_one.vm.network :forwarded_port, guest: 8774, host: 8774
      all_in_one.vm.network :forwarded_port, guest: 8776, host: 8776
      all_in_one.vm.network :forwarded_port, guest: 8777, host: 8777
      all_in_one.vm.network :forwarded_port, guest: 9696, host: 9696
      all_in_one.vm.network :forwarded_port, guest: 8080, host: 8080
      all_in_one.vm.network :forwarded_port, guest: 8000, host: 8000
      all_in_one.vm.network :forwarded_port, guest: 8004, host: 8004
      all_in_one.vm.network :forwarded_port, guest: 80, host: 8880
      all_in_one.vm.network :forwarded_port, guest: 6080, host: 6080
      all_in_one.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", 5 * 1024]
        unless File.exist?(block_file_to_disk)
          v.customize ['createhd', '--filename', block_file_to_disk, '--size', 50 * 1024]
        end
        unless File.exist?(object_file_to_disk)
          v.customize ['createhd', '--filename', object_file_to_disk, '--size', 50 * 1024]
        end
        v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 1, '--device', 0, '--type', 'hdd', '--medium', block_file_to_disk]
        case conf['storage-controller']
        when 'SATAController'
          v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 2, '--device', 0, '--type', 'hdd', '--medium', object_file_to_disk]
	    when 'IDE Controller'
          v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 1, '--device', 1, '--type', 'hdd', '--medium', object_file_to_disk]
        when 'IDE'
          v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 1, '--device', 0, '--type', 'hdd', '--medium', object_file_to_disk]
	    end
      end
      all_in_one.vm.provision "shell", path: conf['package-manager'] + conf['all-in-one-script']
    end

  when 'group'

    config.vm.define :supporting_services do |supporting_services|
      supporting_services.vm.hostname = 'supporting-services'
      supporting_services.vm.network :private_network, ip: '192.168.50.2'
      supporting_services.vm.network :forwarded_port, guest: 5672 , host: 5672 
      supporting_services.vm.network :forwarded_port, guest: 15672 , host: 15672 
      supporting_services.vm.network :forwarded_port, guest: 3306, host: 3306
      supporting_services.vm.network :forwarded_port, guest: 27017, host: 27017
      supporting_services.vm.provision "shell", path: conf['package-manager'] + conf['supporting-services-script']
    end
  
    config.vm.define :controller_services do |controller_services|
      controller_services.vm.hostname = 'controller-services'
      controller_services.vm.network :private_network, ip: '192.168.50.3'
      controller_services.vm.network :forwarded_port, guest: 5000, host: 5000
      controller_services.vm.network :forwarded_port, guest: 35357, host: 35357
      controller_services.vm.network :forwarded_port, guest: 9292, host: 9292
      controller_services.vm.network :forwarded_port, guest: 8774, host: 8774
      controller_services.vm.network :forwarded_port, guest: 8776, host: 8776
      controller_services.vm.network :forwarded_port, guest: 8777, host: 8777
      controller_services.vm.network :forwarded_port, guest: 8080, host: 8080
      controller_services.vm.network :forwarded_port, guest: 80, host: 8880
      controller_services.vm.network :forwarded_port, guest: 6080, host: 6080
      controller_services.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", 3 * 1024]
      end
      controller_services.vm.provision "shell", path: conf['package-manager'] + conf['controller-services-script']
    end

    config.vm.define :compute_services do |compute_services|
      compute_services.vm.hostname = 'compute-services'
      compute_services.vm.network :private_network, ip: '192.168.50.4'
      compute_services.vm.provision "shell", path: conf['package-manager'] + conf['compute-services-script']
      compute_services.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", 3 * 1024]
      end
    end

    config.vm.define :block_storage_services do |block_storage_services|
      block_storage_services.vm.hostname = 'block-storage-services'
      block_storage_services.vm.network :private_network, ip: '192.168.50.5'
      block_storage_services.vm.provision "shell", path: conf['package-manager'] + conf['block-storage-services-script']
      block_storage_services.vm.provider "virtualbox" do |v|
        v.customize ['createhd', '--filename', block_file_to_disk, '--size', 50 * 1024]
        v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 1, '--device', 0, '--type', 'hdd', '--medium', block_file_to_disk]
      end
    end

  when 'microservices'

    config.vm.define :message_broker do |message_broker|
      message_broker.vm.hostname = 'message-broker'
      message_broker.vm.network :private_network, ip: '192.168.50.2'
      message_broker.vm.network :forwarded_port, guest: 5672 , host: 5672 
      message_broker.vm.provision "shell", path: conf['package-manager'] + conf['message-broker-script']
    end

    config.vm.define :database do |database|
      database.vm.hostname = 'database'
      database.vm.network :private_network, ip: '192.168.50.3'
      database.vm.network :forwarded_port, guest: 3306, host: 3306
      database.vm.provision "shell", path: conf['package-manager'] + conf['database-script']
    end

    config.vm.define :identity do |identity|
      identity.vm.hostname = 'identity'
      identity.vm.network :private_network, ip: '192.168.50.4'
      identity.vm.network :forwarded_port, guest: 5000, host: 5000
      identity.vm.network :forwarded_port, guest: 35357, host: 35357
      identity.vm.provision "shell", path: conf['package-manager'] + conf['identity-script']
      #identity.vm.provision "shell", path: conf['package-manager'] + "/keystone_dev.sh"
    end

    config.vm.define :image do |image|
      image.vm.hostname = 'image'
      image.vm.network :private_network, ip: '192.168.50.5'
      image.vm.network :forwarded_port, guest: 9292, host: 9292
      image.vm.provision "shell", path: conf['package-manager'] + conf['image-script']
      #image.vm.provision "shell", path: conf['package-manager'] + "/glance_dev.sh"
    end

    config.vm.define :compute_controller do |compute_controller|
      compute_controller.vm.hostname = 'compute-controller'
      compute_controller.vm.network :private_network, ip: '192.168.50.6'
      compute_controller.vm.network :forwarded_port, guest: 8774, host: 8774
      compute_controller.vm.provision "shell", path: conf['package-manager'] + conf['compute-controller-script']
      compute_controller.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", 2048]
      end
    end

    config.vm.define :compute do |compute|
      compute.vm.hostname = 'compute'
      compute.vm.network :private_network, ip: '192.168.50.7'
      compute.vm.provision "shell", path: conf['package-manager'] + conf['compute-script']
    end

    config.vm.define :network_controller do |network_controller|
      network_controller.vm.hostname = 'network-controller'
      network_controller.vm.network :private_network, ip: '192.168.50.8'
      network_controller.vm.network :forwarded_port, guest: 9696, host: 9696
      network_controller.vm.provision "shell", path: conf['package-manager'] + conf['network-controller-script']
    end

    config.vm.define :dashboard do |dashboard|
      dashboard.vm.hostname = 'dashboard'
      dashboard.vm.network :private_network, ip: '192.168.50.9'
      dashboard.vm.network :forwarded_port, guest: 80, host: 8080
      dashboard.vm.provision "shell", path: conf['package-manager'] + conf['dashboard-script']
    end

    config.vm.define :block_storage_controller do |block_storage_controller|
      block_storage_controller.vm.hostname = 'block-storage-controller'
      block_storage_controller.vm.network :private_network, ip: '192.168.50.10'
      block_storage_controller.vm.network :forwarded_port, guest: 8776, host: 8776
      block_storage_controller.vm.provision "shell", path: conf['package-manager'] + conf['block-storage-controller-script']
    end

    config.vm.define :block_storage do |block_storage|
      block_storage.vm.hostname = 'block-storage'
      block_storage.vm.network :private_network, ip: '192.168.50.11'
      block_storage.vm.provision "shell", path: conf['package-manager'] + conf['block-storage-script']
      block_storage.vm.provider "virtualbox" do |v|
        v.customize ['createhd', '--filename', block_file_to_disk, '--size', 50 * 1024]
        v.customize ['storageattach', :id, '--storagectl', conf['storage-controller'], '--port', 1, '--device', 0, '--type', 'hdd', '--medium', block_file_to_disk]
      end
    end

    config.vm.define :nosql_database do |nosql_database|
      nosql_database.vm.hostname = 'nosql-database'
      nosql_database.vm.network :private_network, ip: '192.168.50.12'
      nosql_database.vm.network :forwarded_port, guest: 27017, host: 27017
      nosql_database.vm.provision "shell", path: conf['package-manager'] + conf['nosql-database-script']
    end

    config.vm.define :telemetry_controller do |telemetry_controller|
      telemetry_controller.vm.hostname = 'telemetry-controller'
      telemetry_controller.vm.network :private_network, ip: '192.168.50.13'
      telemetry_controller.vm.network :forwarded_port, guest: 8777, host: 8777
      telemetry_controller.vm.provision "shell", path: conf['package-manager'] + conf['telemetry-controller-script']
    end

  when 'containerize'

    config.vm.define :container do |container|
      container.vm.hostname = 'container'
      container.vm.network :forwarded_port, guest: 5672 , host: 5672
      container.vm.network :forwarded_port, guest: 3306, host: 3306
      container.vm.network :forwarded_port, guest: 27017, host: 27017
      container.vm.network :forwarded_port, guest: 5000, host: 5000
      container.vm.network :forwarded_port, guest: 35357, host: 35357
      container.vm.network :forwarded_port, guest: 9292, host: 9292
      container.vm.network :forwarded_port, guest: 8774, host: 8774
      container.vm.network :forwarded_port, guest: 8776, host: 8776
      container.vm.network :forwarded_port, guest: 8777, host: 8777
      container.vm.network :forwarded_port, guest: 8080, host: 8080
      container.vm.network :forwarded_port, guest: 80, host: 8880
      container.vm.network :forwarded_port, guest: 6080, host: 6080
      container.vm.provision "shell", path: conf['package-manager'] + conf['container-script']
      container.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", 4 * 1024]
      end
#      container.vm.provision "docker" do |d|
#        d.build_image "/home/vagrant/docker/message-broker", args: "-t electrocucaracha/message-broker"
#        d.run "message-broker", image: "electrocucaracha/message-broker:latest", daemonize: true
#      end
    end

  end

  if conf['enable-rally'] == 'true'
    config.vm.define :benchmark do |benchmark|
      benchmark.vm.hostname = 'benchmark'
      benchmark.vm.network :private_network, ip: '192.168.50.14'
      benchmark.vm.network :forwarded_port, guest: 80 , host: 8081
      benchmark.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", 2 * 1024]
      end
      benchmark.vm.provision "shell", path: conf['package-manager'] + '/rally_' + conf['deployment-style'] + '.sh'
    end
  end

end
