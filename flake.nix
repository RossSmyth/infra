{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena";
    disko.url = "github:nix-community/disko";
  };
  outputs =
    {
      self,
      nixpkgs,
      colmena,
      disko,
      ...
    }:
    {
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ ];
          };
        };

        nice = import ./configuration.nix disko;
      };
    };
}
