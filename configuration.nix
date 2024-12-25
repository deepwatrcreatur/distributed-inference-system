# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "inference1"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

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
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    description = "Anwer Khan";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  #services.displayManager.autoLogin = true;
  services.xserver.displayManager.autoLogin.user = "deepwatrcreatur";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #services.tailscale.enable = true;
  #environment.systemPackages = with pkgs; [ tailscale ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  nushell
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
  zsh
  tmux
  ];

  # Enable ZSH
  programs.zsh.enable = true;
  # Set Zsh as default shell
  users.defaultUserShell = pkgs.zsh;
  # Enable OMZ
  programs.zsh.ohMyZsh.enable = true;
  programs.zsh.ohMyZsh.theme = "bira";
  # Enable Syntax highlighting
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.syntaxHighlighting.highlighters = [ "main" "brackets" "pattern" "cursor" "regexp" "root" "line" ];
  programs.zsh.syntaxHighlighting.styles = { "alias" = "fg=magenta,bold"; };
  programs.zsh.syntaxHighlighting.patterns = { "rm -rf *" = "fg=white,bold,bg=red"; };
  # Enable Zsh Auto Suggest
  programs.zsh.autosuggestions.enable = true;  

  #home-manager = {
  #  useGlobalPkgs = true;
  #  useUserPackages = true;
  #  users.deepwatrcreatur = import ./home.nix;
  #};

  #home-manager.users.deepwatrcreatur = { pkgs, ... }: {                                                                                                     
  #  programs.oh-my-posh.enable = true;                                                                                                           
  #  programs.oh-my-posh.useTheme = "atomic";                                                                                                     
  #  programs.oh-my-posh.enableBashIntegration = true;                                                                                            
  #  #home.stateVersion = "23.11";                                                                                                                 
  #}; 
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ 22 ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  #};
}
