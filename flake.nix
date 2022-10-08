# nixos-rebuild build-vm --flake ".#test"
{
  inputs = {
    nixpkgs.url = "nixpkgs";
    albatross = {
      url = "github:Julow/albatross";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations.test = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [ ./configuration.nix ];
    };
  };
}
