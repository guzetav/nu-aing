{
  description = "Konfigurasi NixOS dengan Flakes + Home Manager 25.11";

  inputs = {
    # Mengunci ke NixOS 25.11
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; 

    # Home Manager source - Arahkan ke branch yang sama dengan nixpkgs
    home-manager = {
      # Menambahkan '/release-25.11' untuk memastikan kecocokan versi
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # Pastikan 'nixos' sesuai dengan hostname di configuration.nix
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          # User 'gustav' sesuai dengan warning tadi
          home-manager.users.gustav = import ./home.nix;

          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
