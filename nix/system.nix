{ config, lib, ... }:
let
  swayLayout = config.programs.sway-layout;
in
{
  imports = [ ./module.nix ];

  config = lib.mkIf (swayLayout.enable && swayLayout.swayConfig) {
    programs.sway.extraConfig = lib.mkAfter ''
      exec ${lib.getExe swayLayout.package} ${swayLayout.configFile}
      ${swayLayout.extraSwayConfig}
    '';
  };
}