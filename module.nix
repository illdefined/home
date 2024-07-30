inputs: user: { config, lib, pkgs, ... }:
let
  inherit (config) hardware;

  graphical =
    if lib.versionAtLeast config.system.stateVersion "24.11"
    then hardware.graphics.enable
    else hardware.opengl.enable;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  environment.etc."xkb/symbols/greedy" = lib.mkIf graphical
    { source = ./greedy.xkb; };

  home-manager = {
    useUserPackages = lib.mkDefault true;
    useGlobalPkgs = lib.mkDefault true;
    users.${user} = inputs.self.homeConfigurations.default;
  };

  programs.fish.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    shell = config.programs.fish.package;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOTvXiNHTXq9wkcxdVOblHVyvcAaCfxmJp/CXI4rzMj"
    ];
  };
}
