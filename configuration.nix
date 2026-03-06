disko:
{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}@args:
{
  deployment = {
    targetHost = "5.161.62.85";
    targetUser = "rsmyth";
  };
  imports = [
    disko.nixosModules.disko
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [
      "2606:4700:4700::1111"
      "1.1.1.1"
      "2001:4860:4860::8888"
      "8.8.8.8"
    ];
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Detroit";
  systemd.coredump.enable = true;
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
  };

  documentation = {
    info.enable = false;
    nixos.enable = false;
  };

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "rsmyth" ];
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  nix = {
    settings = {
      trusted-users = [ "rsmyth" ];
      experimental-features = "nix-command flakes";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
  };

  services.userborn.enable = true;
  users.mutableUsers = false;

  security.sudo.wheelNeedsPassword = false;

  users.users.rsmyth = {
    useDefaultShell = true;
    hashedPassword = "$y$j9T$pANX.P1IbyQB2xriv3ncp/$AnA0t/0WrMitJYBivHKlcdp0d8lqbCuR0yN1zvOnDFA";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOSGfZFizgtHFeI/2khK3PTld8wnn2NiEG29yY3jXNk6 rsmyth@desktop"
    ];
    extraGroups = [
      "wheel"
      "input"
      "networkmanager"
      "docker"
    ];
  };

  systemd.network = {
    enable = true;
    networks."30-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "no";
      address = [
          "5.161.62.85/32"
          "2a01:4ff:f0:4773::/64"
      ];
      routes = [
        { Gateway = "172.31.1.1"; GatewayOnLink = true; }
        { Gateway = "fe80::1"; }
      ];
    };
  };

  networking = {
    firewall.allowedTCPPorts = [
      80
      443
      8448
    ];
    nat.enable = true;
    nat.internalInterfaces = [ "ve-nice" ];
    nat.externalInterface = "enp1s0";
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "test.treefroog.com".extraConfig = ''
        reverse_proxy http://192.168.100.11
      '';

      "matrix.treefroog.com".extraConfig = ''
        reverse_proxy /_matrix/* 192.168.100.22:6167
      '';
      "matrix.treefroog.com:8448".extraConfig = ''
        reverse_proxy /_matrix/* 192.168.100.22:6167
      '';
    };
  };

  containers.test = {
    ephemeral = true;
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.2";
    localAddress = "192.168.100.11";
    config =
      { ... }:
      {
        system.stateVersion = "24.05";

        services.httpd.enable = true;
        services.httpd.adminAddr = "foo@example.org";
        networking.firewall.allowedTCPPorts = [ 80 ];
      };
  };

  containers.matrix = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.2";
    localAddress = "192.168.100.22";
    config =
      { lib, ... }:
      {
        system.stateVersion = "24.05";

        networking.useHostResolvConf = lib.mkForce false;
        services.resolved.enable = true;

        networking.firewall.allowedTCPPorts = [
          80
          443
          8448
          6167
        ];

        services.matrix-conduit = {
          enable = true;
          settings.global = {
            address = "192.168.100.22";
            database_backend = "rocksdb";
            port = 6167;
            server_name = "matrix.treefroog.com";
          };
        };
      };
  };

  system.stateVersion = "24.05";
}
