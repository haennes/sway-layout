{ lib, pkgs }:
let
  pkgSet = pkgs.extend (final: prev: {
    sway-layout = final.callPackage ../pkg.nix { };
  });

  eval = modules: config:
    lib.evalModules {
      modules = modules ++ [
        { _module.args.pkgs = pkgSet; }
        config
      ];
    };

  systemModules = [
    ../system.nix
    {
      options.environment.systemPackages =
        lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
      options.programs.sway = lib.mkOption {
        type = lib.types.submodule {
          options.extraConfig = lib.mkOption { type = lib.types.lines; default = ""; };
        };
        default = { };
      };
    }
  ];

  homeModules = [
    ../homeManager.nix
    {
      options.wayland.windowManager.sway = lib.mkOption {
        type = lib.types.submodule {
          options.config = lib.mkOption {
            type = lib.types.submodule {
              options.extraConfig = lib.mkOption { type = lib.types.lines; default = ""; };
            };
            default = { };
          };
        };
        default = { };
      };
    }
  ];

  commonLayout = {
    workspaces = {
      "1" = {
        tabbed = [
          "foot"
          pkgs.firefox
          {
            splitv = [ pkgs.htop "ncdu" ];
          }
        ];
      };
      "2" = pkgs.htop;
      "3" = { splitv = [ "alacritty -e btop" ]; };
    };
  };

  expectedLayout = builtins.toJSON {
    workspaces = {
      "1" = {
        tabbed = [
          "foot"
          "${pkgs.firefox}/bin/firefox"
          {
            splitv = [ "${pkgs.htop}/bin/htop" "ncdu" ];
          }
        ];
      };
      "2" = { splitv = [ "${pkgs.htop}/bin/htop" ]; };
      "3" = { splitv = [ "alacritty -e btop" ]; };
    };
  };

  good = builtins.tryEval (builtins.toJSON (eval systemModules {
    programs.sway-layout.layout = commonLayout;
  }).config.programs.sway-layout.layout);

  badTag = builtins.tryEval (builtins.toJSON (eval systemModules {
    programs.sway-layout.layout = { workspaces."1" = { bogus = [ "foot" ]; }; };
  }).config.programs.sway-layout.layout);

  badLeaf = builtins.tryEval (builtins.toJSON (eval systemModules {
    programs.sway-layout.layout = { workspaces."1" = { splitv = [ 42 ]; }; };
  }).config.programs.sway-layout.layout);

  badNestedTag = builtins.tryEval (builtins.toJSON (eval systemModules {
    programs.sway-layout.layout = {
      workspaces."1" = {
        tabbed = [ { bogus = [ "foot" ]; } ];
      };
    };
  }).config.programs.sway-layout.layout);

  badNestedLeaf = builtins.tryEval (builtins.toJSON (eval systemModules {
    programs.sway-layout.layout = {
      workspaces."1" = {
        tabbed = [ { splitv = [ 42 ]; } ];
      };
    };
  }).config.programs.sway-layout.layout);

  systemConfig = builtins.tryEval (builtins.toJSON (eval systemModules {
    programs.sway-layout = { enable = true; layout = commonLayout; };
  }).config);

  homeConfig = builtins.tryEval (builtins.toJSON (eval homeModules {
    programs.sway-layout = { enable = true; layout = commonLayout; };
  }).config);
in
assert good.success;
assert good.value == expectedLayout;
assert !badTag.success;
assert !badLeaf.success;
assert !badNestedTag.success;
assert !badNestedLeaf.success;
assert systemConfig.success;
assert lib.hasInfix "/bin/sway-layout" systemConfig.value;
assert homeConfig.success;
assert lib.hasInfix "/bin/sway-layout" homeConfig.value;
pkgs.runCommand "sway-layout-basic-check" { } ''
  echo "module type-checks, normalizes layout, and wires both sway targets" > $out
''