Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-buster64"

  config.vm.network "forwarded_port", guest: 5601, host: 5601, host_ip: "127.0.0.1"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
  end

  config.vm.provision "shell", path: "./setup.sh"
end
