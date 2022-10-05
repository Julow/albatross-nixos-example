{ config, lib, pkgs, inputs, albatross, ... }:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
    "${inputs.nixpkgs}/nixos/modules/profiles/headless.nix"
  ];

  systemd.services.albatross_console = {
    description = "Albatross console daemon (albatross-console)";
    requires = [ "albatross_console.socket" ];
    after = [ "syslog.target" ];
    serviceConfig = {
      Type = "simple";
      User = "albatross";
      Group = "albatross";
      ExecStart = ''
        ${albatross}/bin/albatross-console --systemd-socket-activation --tmpdir="%t/albatross/" -vv
      '';
      RestrictAddressFamilies = "AF_UNIX";
    };
  };

  systemd.sockets.albatross_console = {
    description = "Albatross console socket";
    partOf = [ "albatross_console.service" ];
    socketConfig = {
      ListenStream = "%t/albatross/util/console.sock";
      SocketUser = "albatross";
      SocketMode = "0660";
      Accept = "no";
    };
  };

  systemd.services.albatrossd = {
    description = "Albatross VMM daemon (albatrossd)";
    requires = [ "albatross_console.socket" "albatrossd.socket" ];
    after = [ "syslog.target" "albatross_console.service" "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "albatross";
      ExecStart = ''
        ${albatross}/bin/albatrossd --systemd-socket-activation --tmpdir="%t/albatross/" -vv
      '';
      PIDFile = "%t/albatross/daemon.pid";
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
      Accept = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ ];

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # User for albatross services
  users.users.albatross.isNormalUser = true;
  users.groups.albatross.members = [ "albatross" ];

  users.users.root.initialPassword = "test";
  users.mutableUsers = false;

  system.stateVersion = "22.05";
}
