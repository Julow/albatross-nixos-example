{ nixpkgs, albatross, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/profiles/minimal.nix"
    "${nixpkgs}/nixos/modules/profiles/headless.nix"
    albatross.nixosModules.albatross_service
  ];

  services.albatross.enable = true;

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  users.users.root.initialPassword = "test";
  users.mutableUsers = false;

  system.stateVersion = "22.05";
}
