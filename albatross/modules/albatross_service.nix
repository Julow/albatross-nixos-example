albatross_pkg:
{ config, lib, pkgs, ... }:

let conf = config.services.albatross;

in {
  imports = [
    (import ./albatross_tls_endpoint.nix albatross_pkg)
  ];

  options = with lib;
    with types; {
      services.albatross = {
        enable = mkEnableOption "albatross";

        cacert = mkOption {
          description = "Authority";
          type = path;
        };

      };
    };

  config = lib.mkIf conf.enable {
    systemd.services.albatross-console = {
      description = "Albatross console daemon (albatross-console)";
      requires = [ "albatross-console.socket" ];
      after = [ "syslog.target" ];
      serviceConfig = {
        Type = "simple";
        User = "albatross";
        Group = "albatross";
        ExecStart = ''
          ${albatross_pkg}/bin/albatross-console --systemd-socket-activation --tmpdir="%t/albatross/"
        '';
        RestrictAddressFamilies = "AF_UNIX";
      };
    };

    systemd.sockets.albatross-console = {
      description = "Albatross console socket";
      partOf = [ "albatross-console.service" ];
      socketConfig = {
        ListenStream = "%t/albatross/util/console.sock";
        SocketUser = "albatross";
        SocketMode = "0660";
      };
    };

    # Running as root
    systemd.services.albatrossd = {
      description = "Albatross VMM daemon (albatrossd)";
      requires = [ "albatross-console.socket" "albatrossd.socket" ];
      after = [ "syslog.target" "albatross-console.service" "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "albatross";
        ExecStart = ''
          ${albatross_pkg}/bin/albatrossd --systemd-socket-activation --tmpdir="%t/albatross/"
        '';
        RuntimeDirectoryPreserve = "yes";
        RuntimeDirectory = "albatross";
        ExecStartPre = pkgs.writeShellScript "albatross-start-pre" ''
          mkdir -p %t/albatross/fifo
          chmod 2770 %t/albatross/fifo
          mkdir -p %t/albatross/util
        '';
        ProtectSystem = "full";
        ProtectHome = true;
        OOMScoreAdjust = "-1000";
        IgnoreSIGPIPE = true;
      };
      path = with pkgs; [ iproute util-linux ];
    };

    systemd.sockets.albatrossd = {
      description = "Albatross daemon socket";
      partOf = [ "albatrossd.service" ];
      socketConfig = {
        ListenStream = "%t/albatross/util/vmmd.sock";
        SocketGroup = "albatross";
        SocketMode = "0660";
      };
    };

    # User and group for albatross services
    users.users.albatross.isNormalUser = true;
    users.groups.albatross.members = [ "albatross" ];
  };
}
