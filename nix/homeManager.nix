{ config, lib, ... }:
let
  swayLayout = config.programs.sway-layout;
in
{
  imports = [ ./module.nix ];

  config = lib.mkIf (swayLayout.enable && swayLayout.swayConfig) {
    wayland.windowManager.sway.extraConfig = lib.mkAfter ''
      exec ${lib.getExe swayLayout.package} ${swayLayout.configFile}
      ${swayLayout.extraSwayConfig}
    '';
  };
}
