{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # --- SISTEM & BOOT ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.systemd-boot.configurationLimit = 10; # DIBATASI HANYA 10 SNAPSHOT
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  system.autoUpgrade.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  services.samba.nmbd.enable = false;  
  systemd.services.samba-smbd.wantedBy = lib.mkForce [ "multi-user.target" ];

  system.stateVersion = "25.11";
  nix.settings.trusted-users = [ "root" "gustav" ]; 
 
    
  # Load driver AMD lebih awal (Early KMS) agar resolusi tinggi dari awal boot
  boot.initrd.kernelModules = [ "amdgpu" ];

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
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.plymouth = {
    enable = true;
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
    theme = "cuts"; # Ganti dengan nama tema yang ada di paket tersebut
  };

  hardware.enableAllFirmware = true;

  # --- BOOTSCREEN ---
  services.xserver.displayManager.sessionCommands = ''
  ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1 --mode 1920x1080
'';  


  # --- VIRTUALISASI (KVM & Libvirtd) ---
  virtualisation.libvirtd.enable = true;
  security.polkit.enable = true; 

  # --- NETWORKING & KERNEL OPTIMIZATION ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true; 
  networking.networkmanager.dns = lib.mkForce "none"; 
  networking.nameservers = [ "127.0.0.1" ];
  
  # --- ADGUARD HOME (Agar port 53 tidak bentrok) ---
  services.adguardhome = {
    enable = true;
    openFirewall = true;
  };

  # Menonaktifkan DNS stub listener bawaan systemd agar port 53 bisa dipakai AdGuard Home
  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListener=no
    '';
  };

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
     

     extraConfig = ''
    # Aktifkan dukungan khusus Apple
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
  environment.cinnamon.excludePackages = with pkgs; [
    celluloid

];
  
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
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

  # Aktifkan akselerasi grafis AMD
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- USER ACCOUNT ---
  users.users.gustav = {
    isNormalUser = true;
    description = "gustav";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "samba" "video" "render" ];
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


  # --- Keyboard ---
i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
    fcitx5-mozc          # Engine input Jepang
    fcitx5-gtk           # Dukungan aplikasi GTK
    qt6Packages.fcitx5-configtool    # GUI untuk konfigurasi
  ];
};

# --- HDD ---
fileSystems."/home" = {
  device = "/dev/disk/by-uuid/e11806d0-7a2f-438e-a180-8ecdc4210a4e";
  fsType = "btrfs";
  options = [ 
    "subvol=@home2" 
    "compress=zstd" 
    "noatime"
    "autodefrag"
    "space_cache=v2"
    
  ];
};

fileSystems."/home/gustav/Games" = {
  device = "/dev/disk/by-uuid/e11806d0-7a2f-438e-a180-8ecdc4210a4e";
  fsType = "btrfs";
  options = [ 
    "subvol=@games" 
    "compress=no" 
    "noatime"
    "autodefrag"
    "space_cache=v2"
    "x-gvfs-hide"
  ];
};


  # --- PROGRAMS ---
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

#=====

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
      h = "sudo xed /etc/nixos/home.nix";
      f = "sudo xed /etc/nixos/flake.nix";
      r="cd /etc/nixos && sudo git add . && sudo git commit -m 'update' && sudo nixos-rebuild switch --flake . && git push origin main";
      re = "reboot";
      clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    };
  };

#===== SSH Github ===
    


  # --- ENVIRONMENT SYSTEM PACKAGES ---
  environment.systemPackages = with pkgs; [
    google-chrome 
    wget 
    htop 
    neofetch 
    git
    zsh-powerlevel10k 
    heroic 
    xarchiver 
    zip 
    unzip 
    p7zip
    gnome-disk-utility 
    gparted 
    telegram-desktop 
    gnome-software
    gnome-boxes 
    virt-viewer
    samba
    cifs-utils
    numlockx
    xorg.xrdb
    terminus_font
    pkgs.mint-themes
    ntfs3g
    
  ];

  # --- FONTS ---
  fonts.packages = with pkgs; [
    jetbrains-mono roboto vista-fonts nerd-fonts.jetbrains-mono
  ];
}
