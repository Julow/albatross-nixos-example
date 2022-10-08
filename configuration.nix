{ nixpkgs, albatross, pkgs, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/profiles/minimal.nix"
    "${nixpkgs}/nixos/modules/profiles/headless.nix"
    albatross.nixosModules.albatross
  ];

  services.albatross = {
    enable = true;

    # Enable the TLS endpoint and configure the certificates
    cacert = ./cacert.pem;
    endpoint = {
      enable = true;
      cert = ./server.pem;
      # Configure the server's private key
      # This is not ideal: The key is copied into the Nix store, which is
      # readable by all users on the server and on the developper machine.
      private_key = ./server.key;
    };

    # Forward some ports bind by unikernels
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
