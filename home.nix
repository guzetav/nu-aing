{ config, pkgs, inputs, ... }:

{
  home.username = "gustav";
  home.homeDirectory = "/home/gustav";
  home.stateVersion = "24.11"; 
  home.sessionPath = ["$HOME/.local/bin"];

  home.packages = with pkgs; [
    # Plank Reloaded dan Bamf sudah dihapus dari sini
  ];

  # Bagian autostart Plank (systemd service) sudah dihapus

  programs.git = {
    enable = true;
    # Struktur terbaru untuk NixOS 25.11
    settings = {
      user = {
        name = "guzetav";
        email = "agelegend@yahoo.com";
      };
    };
  };

  programs.home-manager.enable = true;
}
