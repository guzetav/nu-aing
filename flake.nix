{
  description = "Konfigurasi NixOS dengan Flakes + Home Manager 25.11";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; 

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tambahkan ini:
    plank-reloaded.url = "github:zquestz/plank-reloaded";
  };

  outputs = { self, nixpkgs, home-manager, plank-reloaded, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Kita teruskan 'plank-reloaded' melalui specialArgs
      specialArgs = { inherit inputs plank-reloaded; }; 
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.gustav = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs plank-reloaded; };
        }
      ];
    };
  };
}
