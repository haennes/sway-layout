{
  description = "Declarative layout builder for Sway";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          sway-layout = pkgs.callPackage ./nix/pkg.nix {};
          default = sway-layout;
        });

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          basic = pkgs.callPackage ./nix/checks/basic.nix { };
        });


      nixosModules.default = ./nix/system.nix;

      homeManagerModules.default = ./nix/homeManager.nix;

      overlays.default = (final: prev: {
        sway-layout = final.callPackage ./nix/pkg.nix { };
      });
    };
}
