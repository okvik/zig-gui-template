{
  description = "Zig cross-platform GUI application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      zig-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zig = zig-overlay.packages.${system}.master-2024-06-01;
        nativeBuildInputs = with pkgs; [
          zig
          zls
          pkg-config
        ];
        buildInputs = with pkgs; [
          glfw
          wayland
          libxkbcommon
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          xorg.libXinerama
          libGL
          libGLU
          vulkan-headers
          vulkan-loader
          alsa-lib
          freetype
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          inherit nativeBuildInputs buildInputs;
        };
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "zig-gui";
          version = "0.0";
          src = ./.;

          nativeBuildInputs = nativeBuildInputs ++ [
            pkgs.zig.hook
          ];
          inherit buildInputs;
        };
      }
    );
}
