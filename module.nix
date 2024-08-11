inputs: user: { config, lib, pkgs, ... }:
let
  graphical = config.hardware.graphics.enable;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  environment.etc."xkb/symbols/greedy" = lib.mkIf graphical
    { source = ./greedy.xkb; };

  home-manager = {
    useUserPackages = lib.mkDefault true;
    useGlobalPkgs = lib.mkDefault true;
    users.${user} = inputs.self.homeConfigurations.default;
  };

  nixpkgs.config.allowUnfreePredicate = lib.mkIf graphical
    (pkg: builtins.elem (lib.getName pkg) [ "obsidian" ]);

  programs.dconf.enable = lib.mkIf graphical true;
  programs.fish.enable = true;

  services.udev.packages = [
    (pkgs.writeTextDir "/etc/udev/rules.d/98-user-power-supply.rules" ''
      SUBSYSTEM=="power_supply", KERNEL=="AC", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="power-internal.target power-external.target"
    '')
  ];

  systemd.user = {
    targets = {
      power-internal = {
        description = "On internal power supply";
        conflicts = [ "power-external.target" ];
        wantedBy = [ "default.target" ];
        unitConfig = {
          ConditionACPower = false;
          DefaultDependencies = false;
        };
      };

      power-external = {
        description = "On external power supply";
        conflicts = [ "power-internal.target" ];
        wantedBy = [ "default.target" ];
        unitConfig = {
          ConditionACPower = true;
          DefaultDependencies = false;
        };
      };
    };
  };

  users.users.${user} = {
    isNormalUser = true;
    shell = config.programs.fish.package;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICczPHRwY9MAwDGlcB0QgMOJjcpLJhVU3covrW9RBS62AAAABHNzaDo= primary"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAgnEAwe59/yY/U55y7WxGa/QI20/XMQEsQvs1/6LitRAAAABHNzaDo= backup"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOTvXiNHTXq9wkcxdVOblHVyvcAaCfxmJp/CXI4rzMj legacy"
    ];
  };
}
