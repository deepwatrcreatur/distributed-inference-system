{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./cachix.nix
    ];

  # Add your custom binary cache
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.download-buffer-size = 1048576000;

    # List of binary caches to use (default includes cache.nixos.org)
    settings.substituters = [ "https://cache.nixos.org/" "https://cuda-maintainers.cachix.org http://cache.deepwatercreature.com"];
    settings.trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "cache.deepwatercreature.com-1:n7+NSSNvxLJBRpjB8ai2zsVtK1L9mnFtEnulbd4/lUY="
    ];
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "cache.deepwatercreature.com";
        system = "x86_64-linux";  # Adjust if different (check with `uname -m` on cache server)
        maxJobs = 8;  # Match CPU cores or adjust
        speedFactor = 2;  # Priority over other builders
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        sshUser = "deepwatrcreatur";  # Non-root user on cache server
        sshKey = "/root/.ssh/nix-remote";  # Root-owned key for nix-daemon
      }
    ];
    settings = {
      trusted-users = [ "root" "@wheel" ];  # Client-side trust
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [ "networkmanager" "wheel" "ollama"];
    packages = with pkgs; [
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  #services.displayManager.autoLogin = true;
  services.displayManager.autoLogin.user = "deepwatrcreatur";

  home-manager.users.deepwatrcreatur = { pkgs, ... }: {
    home.stateVersion = "24.11"; # Adjust to your NixOS version
    home.file = {
      #".bashrc".source = ./dotfiles/.bashrc;
      ".inputrc".source = ./dotfiles/.inputrc;
      ".gitconfig".source = ./dotfiles/.gitconfig;
      ".terminfo" = {
        source = ./dotfiles/.terminfo;
        recursive = true;
      };
    };
  };

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.kernelParams = [ "nomodeset" "vga=795"];
  boot.kernelModules = [ "ceph" ];
  networking.hostName = "inference1"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  i18n.extraLocaleSettings = {
      LC_ALL = "en_US.UTF-8";
    };
    
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics.enable = true;
  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

  nixpkgs.config.cudaSupport = true; # Enable CUDA system-wide
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #services.tailscale.enable = true;

  # Override Open WebUI to use torch-bin
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  
  environment.variables = {
    GGML_CUDA=1;
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${pkgs.cudaPackages.cudatoolkit}/lib64"
      pkgs.cudaPackages.cudnn
      pkgs.cudaPackages.cuda_cudart
      pkgs.stdenv.cc.cc.lib
    ];
    LLAMA_CPP_MODEL_PATH = "/models/llama_models";
  };
  
  environment.etc."ceph/ceph.conf".text = ''
    [global]
    mon_host = 10.10.11.55:6789  # Replace with your MON addresses
  '';
  environment.etc."ceph/admin.secret".text = ''
    AQBIfuZn15t6BhAACU50sq1eO62VEBzMXpq5HQ==  # Replace with your actual raw key (no [client.admin] or key =)
  '';

  # Define the CephFS mount
  fileSystems."/models" = {
    device = "10.10.11.55:6789:/";  # Replace with your MON address
    fsType = "ceph";
    options = [
      "name=admin"  # Ceph client name
      "secretfile=/etc/ceph/admin.secret"  
      "_netdev"  # Ensures mounting happens after network is up
      "noatime"  # Optional: improves performance
    ];
  };

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    neovim
    helix
    ghostty
    kitty
    nushell
    bat
    fzf
    netdata
    htop
    btop
    git
    gitAndTools.gh
    wget
    curl
    pciutils
    nvtopPackages.full
    elixir
    erlang
    tigerbeetle
    iperf3
    stow
    home-manager
    oh-my-posh
    starship
    tmux
    ollama
    cudaPackages.cudatoolkit
    (llama-cpp.override {
       cudaSupport = true;
       cudaPackages = pkgs.cudaPackages; # Adjust version as needed
    })
    ceph-client
  ];

  environment.interactiveShellInit = ''
      eval "$(oh-my-posh init bash --config ${pkgs.oh-my-posh}/share/oh-my-posh/themes/jandedobbeleer.omp.json)"
    '';


  users.defaultUserShell = pkgs.bash;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.netdata.enable = true;

  services.ollama = {
    enable = true;  # This enables the Ollama service to start automatically
    # Optional settings:
    host = "0.0.0.0";  # Bind to all interfaces (default is 127.0.0.1)
    port = 11434;      # Default port, change if needed
    acceleration = "cuda";  # Enable GPU acceleration (e.g., "cuda" or "rocm")
    environmentVariables = {  # Set custom environment variables if needed
      OLLAMA_HOST = "0.0.0.0";
      HOME = "/models/ollama";
      };
    };
  systemd.services.ollama = {
    environment = {
      HOME = lib.mkForce "/models/ollama";
      OLLAMA_MODELS = lib.mkForce "/models/ollama/models";
    };
    serviceConfig = {
      # Combine all writable paths into a single ReadWritePaths entry
      ReadWritePaths = lib.mkForce [ "/models/ollama" "/models/ollama/models" "/models/ollama/models/blobs" ];
      WorkingDirectory= lib.mkForce "/models/ollama";
      # Optionally, disable StateDirectory if it’s causing issues
      StateDirectory = lib.mkForce "";
    };   
  };

  #services.open-webui = {
  #  enable = true;
  #  port = 8080; # Default WebUI port
  #  host = "0.0.0.0"; # Allow external access
  #};

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ 22 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  fileSystems."/ollama" = {
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
    fsType = "ext4";
    options = [ "defaults" "rw" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
  #};
}
