{
  description = "Konfigurasi NixOS dengan Flakes + Home Manager 25.11";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; 

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Meneruskan inputs ke module lain (seperti configuration.nix dan home.nix)
      specialArgs = { inherit inputs; }; 
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.gustav = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
