Vagrant.configure("2") do |config|
    # Slave configuration
    config.vm.define "Slave" do |slave|
      slave.vm.box = "ubuntu/focal64"
      slave.vm.box_version = "20240821.0.1"
      slave.vm.hostname = "slave"
      slave.vm.network "private_network", ip: "192.168.56.5"
    end
  
    # Master configuration
    config.vm.define "Master" do |master|
      master.vm.box = "ubuntu/focal64"
      master.vm.box_version = "20240821.0.1"
      master.vm.hostname = "master"
      master.vm.network "private_network", ip: "192.168.56.3"
  
      master.vm.provision "shell", inline: <<-SHELL
          sudo apt update
          sudo apt install -y software-properties-common
          sudo add-apt-repository --yes --update ppa:ansible/ansible
          sudo apt update
          sudo apt install -y ansible
      SHELL
    end
  end
  