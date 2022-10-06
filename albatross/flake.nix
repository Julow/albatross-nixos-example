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
    url = "github:Julow/albatross/tls_endpoint_socket";
    flake = false;
  };

  outputs = { self, nixpkgs, opam-nix, flake-utils, albatross }:
    flake-utils.lib.eachDefaultSystem (system: {
      legacyPackages = let
        inherit (opam-nix.lib.${system}) buildOpamProject;
        scope =
          buildOpamProject { } "albatross" albatross { ocaml-system = "*"; };
      in scope.overrideScope' (self: super: {
        # Prevent unnecessary dependencies on the resulting derivation
        albatross = super.albatross.overrideAttrs (_: {
          removeOcamlReferences = true;
          doNixSupport = false;
        });
      });
      defaultPackage = self.legacyPackages.${system}.albatross;

    }) // {
      nixosModules.albatross_service = { pkgs, ... }: {
        imports = [
          (import modules/albatross_service.nix
            self.defaultPackage.${pkgs.system})
        ];

      };
    };
}
