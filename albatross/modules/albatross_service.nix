albatross_pkg:
{ config, lib, pkgs, ... }:

let
  conf = config.services.albatross;

  runtime_dir = "/run/albatross";
  db_dir = "/var/lib/albatross";

  setup_dirs = pkgs.writeShellScript "albatross-setup-dirs" ''
    mkdir -p ${db_dir}
    mkdir -p ${runtime_dir}/fifo
    chmod 2770 ${runtime_dir}/fifo
    mkdir -p ${runtime_dir}/util
  '';

in {
  imports = [ (import ./albatross_tls_endpoint.nix albatross_pkg) ];

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
          ${albatross_pkg}/bin/albatross-console --systemd-socket-activation --tmpdir="${runtime_dir}"
        '';
        RestrictAddressFamilies = "AF_UNIX";
      };
    };

    systemd.sockets.albatross-console = {
      description = "Albatross console socket";
      partOf = [ "albatross-console.service" ];
      socketConfig = {
        ListenStream = "${runtime_dir}/util/console.sock";
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
          ${albatross_pkg}/bin/albatrossd --systemd-socket-activation --tmpdir=${runtime_dir} --dbdir=${db_dir} -vv
        '';
        ExecStartPre = setup_dirs;
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
        ListenStream = "${runtime_dir}/util/vmmd.sock";
        SocketGroup = "albatross";
        SocketMode = "0660";
      };
    };

    # User and group for albatross services
    users.users.albatross.isNormalUser = true;
    users.groups.albatross.members = [ "albatross" ];

    # Network
    networking.bridges.service.interfaces = [ ];
    networking.interfaces.service = {
      ipv4.addresses = [{
        address = "10.0.0.1";
        prefixLength = 24;
      }];
    };
    networking.nat = {
      enable = true;
      internalInterfaces = [ "service" ];
      externalInterface = "eth0";
    };
  };
}
