{ pkgs }: {
  deps = [
    pkgs.love
    pkgs.libGL
    pkgs.libGLU
    pkgs.clang
		pkgs.ccls
		pkgs.gdb
		pkgs.gnumake
  ];
}