{ config, lib, pkgs, ... }:
let
  cfg = config.programs.sway-layout;

  appType = lib.types.oneOf [
    lib.types.str
    lib.types.package
  ];

  containerType = lib.types.attrTag {
    splith = lib.mkOption {
      type = lib.types.listOf nodeType;
      description = "Children arranged side by side.";
    };
    splitv = lib.mkOption {
      type = lib.types.listOf nodeType;
      description = "Children arranged one above the other.";
    };
    tabbed = lib.mkOption {
      type = lib.types.listOf nodeType;
      description = "Children arranged as tabs.";
    };
    stacking = lib.mkOption {
      type = lib.types.listOf nodeType;
      description = "Children arranged as a stack.";
    };
  };

  nodeType = lib.types.oneOf [
    appType
    containerType
  ];

  workspaceType = lib.types.oneOf [
    appType
    containerType
  ];

  commandOf = node:
    if lib.isString node then node
    else lib.getExe node;

  normalizeNode = node:
    if lib.isAttrs node && !lib.isDerivation node then
      lib.mapAttrs (_: children: map normalizeNode children) node
    else
      commandOf node;

  normalizeWorkspace = ws:
    if lib.isAttrs ws && !lib.isDerivation ws then
      normalizeNode ws
    else
      { splitv = [ (commandOf ws) ]; };
in
{
  options.programs.sway-layout = {
    enable = lib.mkEnableOption "sway-layout, the declarative layout builder for Sway";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.sway-layout;
      defaultText = lib.literalExpression "pkgs.sway-layout";
      description = "sway-layout package to use.";
    };

    layout = lib.mkOption {
      type = lib.types.submodule {
        options.workspaces = lib.mkOption {
          type = lib.types.attrsOf workspaceType;
          description = "Mapping from workspace name to its layout.";
        };
      };
      default = { };
      example = lib.literalExpression ''
        {
          workspaces = {
            "1" = {
              tabbed = [
                "foot"
                "firefox"
                {
                  splitv = [ pkgs.htop "ncdu" ];
                }
              ];
            };
            "2" = pkgs.firefox;
            "3" = {
              splitv = [ pkgs.htop "alacritty" ];
            };
          };
        }
      '';
      description = ''
        Layout definition. Each workspace maps to either a program or a
        container. A program is a shell command string or a package, placed as
        a single program in a splitv container. A container is an attrTag
        choosing one of `splith`, `splitv`, `tabbed` or `stacking`, listing the
        programs and nested containers it contains. Packages at any depth are
        normalized to their executable path.
      '';
      apply = layoutDef: layoutDef // {
        workspaces = lib.mapAttrs (_: normalizeWorkspace) layoutDef.workspaces;
      };
    };

    layoutFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to an existing JSON layout config, used instead of
        {option}`layout`.
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      description = ''
        Path of the JSON layout config passed to sway-layout. Either generated
        from {option}`layout` or {option}`layoutFile` when set.
      '';
    };

    swayConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to add an `exec sway-layout` line to the sway configuration.
      '';
    };

    extraSwayConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        exec_always sway-layout --force
      '';
      description = ''
        Additional sway configuration lines appended after the
        automatically generated `exec sway-layout` line.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.sway-layout.configFile =
      if cfg.layoutFile != null then cfg.layoutFile
      else pkgs.writeText "sway-layout.json" (builtins.toJSON cfg.layout);
  };
}
