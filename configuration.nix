{ nixpkgs, albatross, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/profiles/minimal.nix"
    "${nixpkgs}/nixos/modules/profiles/headless.nix"
    albatross.nixosModules.albatross_service
  ];

  services.albatross = {
    enable = true;
    cacert = ./cacert.pem;
    endpoint = {
      enable = true;
      cert = ./server.pem;
      private_key = ./server.key;
    };
    forwardPorts = [
      {
        destination = "10.0.0.2:8080";
        proto = "tcp";
        sourcePort = 8080;
      }
      {
        destination = "10.0.0.2:4433";
        proto = "tcp";
        sourcePort = 4433;
      }
    ];
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  users.users.root.initialPassword = "test";
  users.mutableUsers = false;

  system.stateVersion = "22.05";
}
