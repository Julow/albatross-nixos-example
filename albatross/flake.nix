{
  inputs.opam-nix = {
    url = "github:Julow/opam-nix"; # Fork of github:tweag/opam-nix
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs.url = "nixpkgs";
  inputs.albatross = {
    url = "github:roburio/albatross";
    flake = false;
  };

  outputs = { self, nixpkgs, opam-nix, flake-utils, albatross }:
    flake-utils.lib.eachDefaultSystem (system: rec {
      legacyPackages = with opam-nix.lib.${system};
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Taken from example https://github.com/tweag/opam-nix/blob/main/examples/opam-ed/flake.nix
          scope = queryToScope { inherit pkgs; } {
            albatross = "*";
            ocaml-system = "*";
          };
          overlay = self: super: {
            # Prevent unnecessary dependencies on the resulting derivation
            albatross = super.albatross.overrideAttrs (_: {
              removeOcamlReferences = true;
              postFixup = "rm -rf $out/nix-support";
            });
          };
        in scope.overrideScope' overlay;

      defaultPackage = legacyPackages.albatross;

    }) // {
      nixosModules.albatross_service = { pkgs, ... }: {
        imports = [
          (import modules/albatross_service.nix
            self.defaultPackage.${pkgs.system})
        ];

      };
    };
}
