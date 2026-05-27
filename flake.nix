{
  description = "BMWAdam's configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    xremap-flake.url = "github:xremap/nix-flake";
    nix-colors.url = "github:misterio77/nix-colors";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-grub-themes.url = "github:jeslie0/nixos-grub-themes";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    firefox-addons,
    flake-utils,
    sops-nix,
    nixos-grub-themes,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    # packages = flake-utils.lib.eachDefaultSystem (system: import ./pkgs nixpkgs.legacyPackages.${system});
    formatter = flake-utils.lib.eachDefaultSystem (system: nixpkgs.legacyPackages.${system}.alejandra);

    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    nixosConfigurations = {
      omnibook = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};

        modules = [
          inputs.sops-nix.nixosModules.sops
          ./modules/omnibook/proximity.nix
          ./modules/omnibook/secrets.nix
          ./modules/omnibook/ollama.nix
          ./modules/omnibook/fingerprint.nix
          ./modules/omnibook/hardware-configuration.nix
          ./modules/configuration.nix
          ./modules/wifi.nix
        ];
      };
    };
  };
}
