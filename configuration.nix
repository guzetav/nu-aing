{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # --- SISTEM & BOOT ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  system.stateVersion = "25.11";

  # --- VIRTUALISASI (KVM & Libvirtd) ---
  virtualisation.libvirtd.enable = true;
  security.polkit.enable = true; 

  # --- NETWORKING & KERNEL OPTIMIZATION ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };

  # --- SAMBA ---
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixos-smb";
        "netbios name" = "nixos";
        "security" = "user";
        "map to guest" = "bad user";
      };
      public = {
        "path" = "/home/gustav/";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "gustav";
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  # --- LOKALISASI & WAKTU ---
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # --- DESKTOP ENVIRONMENT (CINNAMON) ---
  services.flatpak.enable = true;
  services.packagekit.enable = true; 
  services.gvfs.enable = true; 

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  services.xserver = {
    enable = true;
    desktopManager.cinnamon.enable = true;
    displayManager.setupCommands = "${pkgs.numlockx}/bin/numlockx on";
    
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  
  services.displayManager.autoLogin = {
    enable = true;
    user = "gustav";
  };
  
  # Diubah: Menghapus tema Gruvbox dari Slick Greeter
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.slick = {
      enable = true;
      # Tema akan kembali ke default (Adwaita/System)
    };
  };

  services.displayManager.defaultSession = "cinnamon";

  # --- HARDWARE & AUDIO ---
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- USER ACCOUNT ---
  users.users.gustav = {
    isNormalUser = true;
    description = "gustav";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "samba" ];
    shell = pkgs.zsh;
  };

  # --- NIX SETTINGS & CLEANUP ---
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    auto-optimise-store = true;
    download-buffer-size = 134217728; 
    max-jobs = "auto";
    experimental-features = [ "nix-command" "flakes" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # --- PROGRAMS ---
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    # Diubah: Menghapus script perubahan warna Terminal (Gruvbox HEX codes)
    interactiveShellInit = ''
      export TERM="xterm-256color"
    '';
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
    };
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    shellAliases = {
      c = "sudo xed /etc/nixos/configuration.nix"; 
      r = "sudo git add . && sudo nixos-rebuild switch --flake .";
      re = "reboot";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    };
  };

  # --- ENVIRONMENT SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    google-chrome 
    wget 
    htop 
    neofetch 
    git
    zsh-powerlevel10k 
    heroic xarchiver 
    zip 
    unzip 
    p7zip
    gnome-disk-utility 
    gparted 
    telegram-desktop 
    gnome-software
    gnome-boxes 
    spice-gtk 
    spice-protocol 
    virt-viewer
gnome-text-editor        
    samba
    cifs-utils
    numlockx
   xorg.xrdb
  
  
  
  
  
  
  
  
  
  ];

  # --- FONTS ---
  fonts.packages = with pkgs; [
    jetbrains-mono roboto vista-fonts nerd-fonts.jetbrains-mono
  ];
}
