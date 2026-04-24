{
  description = "mp.nvim - A plugin for using mp commands in Neovim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "mp.nvim";

          packages = with pkgs; [
            lua-language-server
            luajitPackages.luacheck
            stylua
          ];
        };
      }
    );
}
