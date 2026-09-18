{buildGoModule, lib, ...}:  buildGoModule {
  pname = "sway-layout";
  version = "0.1.0";
  src = ./..;

  vendorHash = null;

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Reliably arrange auto-started applications in complex layouts, via sway IPC";
    mainProgram = "sway-layout";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
