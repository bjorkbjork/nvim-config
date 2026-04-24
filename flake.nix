{
  description = "Portable neovim environment — nvim + treesitter parsers + LSPs, reproducible via nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Prebuilt treesitter parsers bundled with the nvim-treesitter plugin.
        # init.lua disables lazy's auto_install when NVIM_NIX=1, so these are
        # the parsers the editor will use.
        treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
          p.bash p.c p.cpp p.diff p.html p.lua p.luadoc p.markdown
          p.markdown_inline p.query p.vim p.vimdoc p.python p.javascript
          p.typescript p.tsx p.json p.yaml p.toml p.rust p.go p.nix
          p.dockerfile p.gitignore p.gitcommit p.gitattributes p.regex
        ]);

        # Neovim with the treesitter plugin bundled into its "start" pack,
        # so parsers are on runtimepath without lazy.nvim compiling anything.
        nvim = pkgs.neovim.override {
          configure = {
            packages.nix = {
              start = [ treesitter ];
            };
          };
        };

        # LSPs and formatters referenced by init.lua's `servers` table and
        # conform.nvim's formatter config. All discovered via $PATH — no Mason.
        tools = with pkgs; [
          lua-language-server                       # lua_ls
          clang-tools                               # clangd
          python3Packages.python-lsp-server         # pylsp (manually wired in init.lua)
          nixd                                      # nixd (Nix LSP)
          rust-analyzer                             # rust_analyzer
          typescript-language-server                # ts_ls
          typescript                                # tsserver — ts_ls depends on it
          black                                     # python formatter (via pylsp-black)
          stylua                                    # lua formatter (via conform.nvim)
          ripgrep                                   # telescope grep
          fd                                        # telescope find
          gcc                                       # fallback for any plugin that still shells out
          git                                       # for lazy.nvim plugin installs
        ];
      in {
        packages.default = pkgs.symlinkJoin {
          name = "nvim-env";
          paths = [ nvim ] ++ tools;
          buildInputs = [ pkgs.makeWrapper ];
          # Flag the environment so init.lua knows to skip Mason/auto-install paths.
          postBuild = ''
            wrapProgram $out/bin/nvim --set NVIM_NIX 1
          '';
        };
      });
}
