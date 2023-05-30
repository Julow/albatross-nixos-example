# nixos-rebuild build-vm --flake ".#test"
{
  inputs = {
    nixpkgs.url = "nixpkgs";
    albatross = {
      url = "github:roburio/albatross";
      inputs.nixpkgs.follows =
        "nixpkgs"; # Avoid evaluating two different versions of nixpkgs
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
