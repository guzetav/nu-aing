{ config, pkgs, inputs, ... }:

{
  home.username = "gustav";
  home.homeDirectory = "/home/gustav";
  home.stateVersion = "24.11"; 

  home.packages = with pkgs; [
    inputs.plank-reloaded.defaultPackage.${pkgs.system}
    libbamf
    
    # Tambahkan Ulauncher di sini
    ulauncher
  ];

  # Autostart untuk Plank (yang tadi)
  systemd.user.services.plank = {
    Unit = {
      Description = "Plank Dock Reloaded";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${inputs.plank-reloaded.defaultPackage.${pkgs.system}}/bin/plank";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # Tambahkan Autostart untuk Ulauncher
  systemd.user.services.ulauncher = {
    Unit = {
      Description = "Ulauncher Application Launcher";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      # --hide-window agar dia jalan di background saat startup
      ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  programs.git = {
    enable = true;
    userName = "guzetav"; 
    userEmail = "agelegend@yahoo.com";
  };

  programs.home-manager.enable = true;
}
