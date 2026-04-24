{
  description = "Portable dev environment — ships nvim, LSPs, formatters, and runtime deps. One source of truth for every machine that runs this config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.buildEnv {
          name = "nvim-env";
          paths = with pkgs; [
            # Editor.
            neovim

            # Baseline: lazy.nvim clones with git; treesitter compiles parsers
            # with gcc + tree-sitter CLI; telescope uses ripgrep + fd.
            gcc
            git
            ripgrep
            lua55Packages.tree-sitter-cli
            fd

            # Language servers — must match the `servers` table in init.lua.
            # lspconfig looks each one up on $PATH.
            lua-language-server                  # lua_ls
            clang-tools                          # clangd
            rust-analyzer                        # rust_analyzer
            typescript-language-server           # ts_ls
            nixd                                 # nixd
            python3Packages.python-lsp-server    # pylsp (wired manually in init.lua)

            # Formatters — invoked by conform.nvim / pylsp plugins.
            stylua
            black
          ];
        };
      });
}
