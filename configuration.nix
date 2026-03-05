{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}@args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

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
  services.openssh.enable = true;

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
  system.stateVersion = "24.05";
}
