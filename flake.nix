{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    en_EU.url = "git+https://woof.rip/mikael/en_EU.git";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    inherit (nixpkgs) lib;
  in {
    nixosModules.default = import ./module.nix inputs;
    homeConfigurations.default = import ./home.nix inputs;

    checks = lib.genAttrs lib.systems.flakeExposed (system: {
      home = (home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          self.homeConfigurations.default {
            home.username = "nil";
            home.homeDirectory = "/home/nil";
          }
        ];
      }).activationPackage;
    } // lib.optionalAttrs (lib.hasSuffix "-linux" system) {
      nixos = (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (self.nixosModules.default "nil") {
            boot.loader.grub.enable = false;
            fileSystems."/".device = "nodev";
            hardware.graphics.enable = true;
            location = {
              provider = "manual";
              latitude = 90.0;
              longitude = 0.0;
            };
            system.stateVersion = lib.versions.majorMinor lib.version;
          }
        ];
      }).config.system.build.toplevel;
    });

    hydraJobs.checks = { inherit (self.checks) x86_64-linux; };
  };
}
