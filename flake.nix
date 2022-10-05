# nixos-rebuild build-vm --flake ".#test"
{
  inputs = {
    nixpkgs.url = "nixpkgs";
    albatross = {
      url = "path:./albatross";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, albatross, ... }@inputs: {
    nixosConfigurations.test = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        albatross = albatross.defaultPackage.${system};
      };
      modules = [ ./configuration.nix ];
    };
  };
}
