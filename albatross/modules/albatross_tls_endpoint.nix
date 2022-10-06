albatross_pkg:
{ config, lib, pkgs, ... }:

let
  conf = config.services.albatross.endpoint;
  enabled = config.services.albatross.enable && conf.enable;
  cacert = config.services.albatross.cacert;

in {
  options = with lib;
    with types; {
      services.albatross.endpoint = {
        enable = mkEnableOption "albatross tls endpoint";

        port = mkOption {
          type = port;
          default = 1025;
        };

        cert = mkOption {
          description =
            "TLS certificate used to authenticate the endpoint. Should be signed by the certificate passed to 'services.albatross.ca'.";
          type = path;
        };

        private_key = mkOption {
          description = "Private key corresponding to the 'cert'.";
          type = path;
        };

      };
    };

  config = lib.mkIf enabled {
    systemd.services.albatross-tls-endpoint = {
      description = "Albatross tls endpoint";
      requires = [ "albatrossd.socket" "albatross-tls-endpoint.socket" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "albatross";
        Group = "albatross";
        ExecStart = ''
          ${albatross_pkg}/bin/albatross-tls-endpoint --systemd-socket-activation --tmpdir="%t/albatross/" ${cacert} ${conf.cert} ${conf.private_key}
        '';
      };
    };

    systemd.sockets.albatross-tls-endpoint = {
      description = "Albatross tls endpoint listening for requests";
      partOf = [ "albatross-tls-endpoint.service" ];
      socketConfig = {
        ListenStream = conf.port;
        SocketUser = "albatross";
        SocketMode = "0660";
      };
    };

    networking.firewall.allowedTCPPorts = [ conf.port ];
  };
}
