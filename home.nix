{ config, pkgs, inputs, ... }:

{
  home.username = "gustav";
  home.homeDirectory = "/home/gustav";
  home.stateVersion = "24.11"; 
  home.sessionPath = ["$HOME/.local/bin"];

  home.packages = with pkgs; [
    inputs.plank-reloaded.defaultPackage.${pkgs.system}
    bamf
  ];

  # Autostart untuk Plank
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

  programs.git = {
    enable = true;
    userName = "guzetav"; 
    userEmail = "agelegend@yahoo.com";
  };

  programs.home-manager.enable = true;
}
