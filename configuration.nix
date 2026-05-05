{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # 1. SISTEM & BOOTLOADER
  # ============================================================================
  system.stateVersion = "25.11";

  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [ 
    "video=1920x1080@60" 
    "quiet" 
    "splash" 
    "vt.global_cursor_default=0" 
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "fbcon=nodefer"
  ];

  boot.plymouth = {
    enable = true;
    theme = "onepiece";
    themePackages = [
      (pkgs.stdenv.mkDerivation {
        name = "onepiece-theme";
        src = ./themes/onepiece; 
        installPhase = ''
          mkdir -p $out/share/plymouth/themes/onepiece
          cp -r * $out/share/plymouth/themes/onepiece/
          sed -i "s|/usr/share/plymouth/themes|$out/share/plymouth/themes|g" $out/share/plymouth/themes/onepiece/onepiece.plymouth
        '';
      })
    ];
  };

  # ============================================================================
  # 2. NETWORKING & OPTIMIZATION
  # ============================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkForce "none";
  networking.nameservers = [ "127.0.0.1" ];

  services.adguardhome = {
    enable = true;
    openFirewall = true;
  };

  services.resolved = {
    enable = true;
    extraConfig = "DNSStubListener=no";
  };

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  # ============================================================================
  # 3. DESKTOP ENVIRONMENT (CINNAMON)
  # ============================================================================
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    desktopManager.cinnamon.enable = true;
    displayManager.setupCommands = "${pkgs.numlockx}/bin/numlockx on";
    displayManager.sessionCommands = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1 --mode 1920x1080
    '';
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager = {
    defaultSession = "cinnamon";
    autoLogin = {
      enable = true;
      user = "gustav";
    };
  };

  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.slick.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
  services.flatpak.enable = true;
  services.gvfs.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.enableAllFirmware = true;

  # ============================================================================
  # 4. AUDIO (PIPEWIRE)
  # ============================================================================
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ============================================================================
  # 5. USERS & LOKALISASI (FIXED)
  # ============================================================================
  time.timeZone = "Asia/Tokyo";
  
  # Perbaikan Error Locale: Menggunakan opsi yang benar
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ja_JP.UTF-8/UTF-8" ];

  users.users.gustav = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "samba" "video" "render" ];
    shell = pkgs.zsh;
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk qt6Packages.fcitx5-configtool ];
  };

  # ============================================================================
  # 6. STORAGE & FILESYSTEMS (BTRFS BINDS)
  # ============================================================================
  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-uuid/e11806d0-7a2f-438e-a180-8ecdc4210a4e";
    fsType = "btrfs";
    options = [ "subvol=@backup" "compress=zstd" "noatime" "autodefrag" "space_cache=v2" "x-gvfs-hide" ];
  };

  fileSystems."/home/gustav/Documents" = { device = "/mnt/hdd/Documents"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/Downloads" = { device = "/mnt/hdd/Downloads"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/Games" = {
    device = "/dev/disk/by-uuid/e11806d0-7a2f-438e-a180-8ecdc4210a4e";
    fsType = "btrfs";
    options = [ "subvol=@games" "compress=no" "noatime" "autodefrag" "space_cache=v2" "x-gvfs-hide" ];
  };
  fileSystems."/home/gustav/Handphone" = { device = "/mnt/hdd/Handphone"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/Music" = { device = "/mnt/hdd/Music"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/Pictures" = { device = "/mnt/hdd/Pictures"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/Software" = { device = "/mnt/hdd/Software"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/TomoTrading" = { device = "/mnt/hdd/TomoTrading"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };
  fileSystems."/home/gustav/Videos" = { device = "/mnt/hdd/Videos"; fsType = "none"; options = [ "bind" "x-gvfs-hide"]; };

  # ============================================================================
  # 7. PROGRAMS (ZSH, STEAM, ULAUNCHER)
  # ============================================================================
  programs.steam.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
    };
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    shellAliases = {
      c = "sudo xed /etc/nixos/configuration.nix"; 
      h = "sudo xed /etc/nixos/home.nix";
      r = "cd /etc/nixos && sudo git add . && sudo git commit -m 'update' && sudo nixos-rebuild switch --flake . && git push origin main";
      re = "reboot";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
      ai = "gemini";
    };
  };

  # ============================================================================
  # 8. SYSTEM PACKAGES
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    google-chrome wget htop fastfetch git
    zsh-powerlevel10k heroic xarchiver zip unzip p7zip
    gnome-disk-utility gparted telegram-desktop
    samba cifs-utils numlockx fzf fd libnotify
    
    # Launcher pilihanmu
    ulauncher
  ];

  # ============================================================================
  # 9. NIX SETTINGS & MAINTENANCE
  # ============================================================================
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "gustav" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
