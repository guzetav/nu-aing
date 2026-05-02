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
      configurationLimit = 10; # Dibatasi hanya 10 snapshot
    };
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Silent Boot & AMD Early KMS
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
  # 2. NETWORKING, DNS (ADGUARD), & OPTIMIZATION
  # ============================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = lib.mkForce "none";
  networking.nameservers = [ "127.0.0.1" ];

  # AdGuard Home (Agar port 53 tidak bentrok)
  services.adguardhome = {
    enable = true;
    openFirewall = true;
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  # TCP Optimization (BBR)
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
  # 3. DESKTOP ENVIRONMENT & GRAPHICS
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

  # Portal & Integration
  services.flatpak.enable = true;
  services.packagekit.enable = true;
  services.gvfs.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  environment.cinnamon.excludePackages = with pkgs; [ celluloid ];

  # Graphics Acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.enableAllFirmware = true;

  # ============================================================================
  # 4. AUDIO & PRINTING
  # ============================================================================
  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ============================================================================
  # 5. STORAGE & FILESYSTEMS (HDD & BTRFS)
  # ============================================================================
#  fileSystems."/home" = {
#    device = "/dev/disk/by-uuid/e11806d0-7a2f-438e-a180-8ecdc4210a4e";
#    fsType = "btrfs";
#    options = [ "subvol=@home2" "compress=zstd" "noatime" "autodefrag" "space_cache=v2" ];
#  };

#  fileSystems."/home/gustav/Games" = {
#    device = "/dev/disk/by-uuid/e11806d0-7a2f-438e-a180-8ecdc4210a4e";
#    fsType = "btrfs";
#    options = [ "subvol=@games" "compress=no" "noatime" "autodefrag" "space_cache=v2" "x-gvfs-hide" ];
#  };

  # ============================================================================
  # 6. FILE SHARING (SAMBA & AVAHI)
  # ============================================================================
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
        "extraConfig" = ''
          vfs objects = catia fruit streams_xattr
          fruit:aapl = yes
          fruit:metadata = stream
          fruit:model = MacSamba
          fruit:posix_rename = yes
          fruit:veto_appledouble = no
          fruit:wipe_intentionally_left_blank_rfork = yes
          fruit:delete_empty_adfiles = yes
        '';
      };
      NuAing = {
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

  services.samba.nmbd.enable = false;
  systemd.services.samba-smbd.wantedBy = lib.mkForce [ "multi-user.target" ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  # ============================================================================
  # 7. VIRTUALISASI & SECURITY
  # ============================================================================
  virtualisation.libvirtd.enable = true;
  security.polkit.enable = true;

  # ============================================================================
  # 8. USERS & LOKALISASI
  # ============================================================================
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

  users.users.gustav = {
    isNormalUser = true;
    description = "gustav";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "samba" "video" "render" "vboxusers" ];
    shell = pkgs.zsh;
  };

  nix.settings.trusted-users = [ "root" "gustav" ];

  # Input Method (Japanese)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  # ============================================================================
  # 9. PROGRAMS & GAMING
  # ============================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # Zsh Configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
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
      ho = "sudo xed /etc/nixos/hardware-configuration.nix";
      c = "sudo xed /etc/nixos/configuration.nix"; 
      h = "sudo xed /etc/nixos/home.nix";
      f = "sudo xed /etc/nixos/flake.nix";
      r = "cd /etc/nixos && sudo git add . && sudo git commit -m 'update' && sudo nixos-rebuild switch --flake . && git push origin main";
      re = "reboot";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
      ai = "gemini";
    };
  };

  # ============================================================================
  # 10. SYSTEM PACKAGES & FONTS
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    google-chrome wget htop fastfetch git
    zsh-powerlevel10k heroic xarchiver zip unzip p7zip
    gnome-disk-utility gparted telegram-desktop gnome-software
    gnome-boxes virt-viewer samba cifs-utils numlockx
    xorg.xrdb terminus_font pkgs.mint-themes ntfs3g
    gemini-cli zsh-completions
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono roboto vista-fonts nerd-fonts.jetbrains-mono
  ];

  # ============================================================================
  # 11. MAINTENANCE & AUTO-CLEANUP
  # ============================================================================
  system.autoUpgrade.enable = true;

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
}
