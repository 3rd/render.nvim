# 🖼️ image.nvim

This plugin attempts to add image support to Neovim.

It works wonderfully with Kitty + Tmux, and it handles painful things like rendering an image
at a given position in a buffer, scrolling, windows, etc.

It has built-in Markdown and Neorg integrations that you can use right now.
\
It can also render image files as images when opened.

Join on Discord: https://discord.gg/GTwbCxBNgz

https://github.com/3rd/image.nvim/assets/59587503/9a9a1792-6476-4d96-8b8e-d3cdd7f5759e

## Installation

This plugin requires a few external dependencies. Here is a list, there are instructions for
specific plugin managers below.

**Mandatory Deps:**

- [ImageMagick](https://github.com/ImageMagick/ImageMagick) - see [Installing ImageMagick](#installing-imagemagick)
- [magick LuaRock](https://github.com/leafo/magick)

You need **one of:**

- [Kitty](https://sw.kovidgoyal.net/kitty/) >= 28.0 - for the `kitty` backend
- [ueberzugpp](https://github.com/jstkdng/ueberzugpp) - for the `ueberzug` backend

Fully **optional:**

- [curl](https://github.com/curl/curl) - for remote images

### Installing The Plugin & Rock

<details>

<summary>Lazy.nvim</summary>

> Since version v11.\* of Lazy rockspec is supported, so no need of extra plugins `vhyrro/luarocks.nvim`

<details>
<summary><b>Lazy >= v11.* [(DISABLED DUE TO ISSUES)](https://github.com/3rd/image.nvim/issues/191)</b></summary>

```lua
{
    "3rd/image.nvim",
    config = function()
        -- ...
    end
}
```

</details>

<details>
<summary><b>Lazy < v11.x</b></summary>

**NOTE:** Don't forget to install the imageMagick system package, detailed [below](#installing-imagemagick)

It's recommended that you use [vhyrro/luarocks.nvim](https://github.com/vhyrro/luarocks.nvim) to
install luarocks for neovim while using lazy. But you can install manually as well.

**With luarocks.nvim**:
**Please readthe luarocks.nvim README,** it currently has an external dependency.

```lua
{
    "vhyrro/luarocks.nvim",
    priority = 1001, -- this plugin needs to run before anything else
    opts = {
        rocks = { "magick" },
    },
},
{
    "3rd/image.nvim",
    dependencies = { "luarocks.nvim" },
    config = function()
        -- ...
    end
}
```

</details>

---

**OR Without luarocks.nvim**:

You have to install the luarock manually.

1. install [luarocks](https://luarocks.org/) on your system via your system package manager
2. run `luarocks --local --lua-version=5.1 install magick`

```lua
-- Example for configuring Neovim to load user-installed installed Lua rocks:
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"

-- lazy snippet
{
    "3rd/image.nvim",
    config = function()
        -- ...
    end
}
```

</details>

<details>
  <summary>Rocks.nvim</summary>

**NOTE:** Don't forget to install the imageMagick system package, detailed [below](#installing-imagemagick)

`:Rocks install image.nvim`

</details>

<details>
  <summary>NixOS</summary>

NixOS users need to install `imagemagick` and `luajitPackages.magick`
([thanks](https://github.com/NixOS/nixpkgs/pull/243687) to
[@donovanglover](https://github.com/donovanglover)).

It's recommended that you can build your Neovim with those packages like so:

<details>

<summary>With home-manager</summary>

_thanks to [@wuliuqii](https://github.com/wuliuqii) in [#13](https://github.com/3rd/image.nvim/issues/13)_

```nix
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    extraLuaPackages = ps: [ ps.magick ];
    extraPackages = ps: [ ps.imagemagick ];
    # ... other config
  };
}
```

</details>

<details>
  <summary>Vanilla NixOS</summary>

```nix
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/utils.nix#L27
{ pkgs, neovimUtils, wrapNeovimUnstable, ... }:

let
  config = pkgs.neovimUtils.makeNeovimConfig {
    extraLuaPackages = p: [ p.magick ];
    extraPackages = p: [ p.imagemagick ];
    # ... other config
  };
in {
  nixpkgs.overlays = [
    (_: super: {
      neovim-custom = pkgs.wrapNeovimUnstable
        (super.neovim-unwrapped.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [ super.tree-sitter ];
        })) config;
    })
  ];
  environment.systemPackages = with pkgs; [ neovim-custom ];
}
```

</details>
</details>

### Installing ImageMagick

The `magick` luarock provides bindings to ImageMagick's MagickWand, so we need to install that
package as well.

- Ubuntu: `sudo apt install libmagickwand-dev`
- MacOS:
  - Homebrew: `brew install imagemagick`
    - By default, homebrew installs into a weird location, so you have to add `$(brew --prefix)/lib` to
    `DYLD_LIBRARY_PATH` by adding something like
    `export DYLD_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_LIBRARY_PATH"`
    to your shell profile (probably `.zshrc` or `.bashrc`)
  - MacPorts: `sudo port install imagemagick`
    - You must add `/opt/local/lib` to `DYLD_LIBRARY_PATH`, similar to homebrew.
- Fedora: `sudo dnf install ImageMagick-devel`
- Arch: `sudo pacman -Syu imagemagick`

## Configuration

```lua
-- default config
require("image").setup({
  backend = "kitty",
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      only_render_image_at_cursor_mode = "inline", -- "inline" or "popup"
      filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
    },
    neorg = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "norg" },
    },
    html = {
      enabled = false,
    },
    css = {
      enabled = false,
    },
  },
  max_width = nil,
  max_height = nil,
  max_width_window_percentage = nil,
  max_height_window_percentage = 50,
  window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
  tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
})
```

## Tmux

- You must use tmux [>= 3.3](https://github.com/tmux/tmux/wiki/FAQ#:~:text=tmux%203.3%2C%20the-,allow%2Dpassthrough,-option%20must%20be) and set: `set -gq allow-passthrough on`
- If you want the images to be automatically hidden/shown when you switch windows (`tmux_show_only_in_active_window = true`), set: `set -g visual-activity off`

### Try it out with a minimal setup

Download [minimal-setup.lua](./minimal-setup.lua) from the root of this repository and run the demo with:

```sh
nvim --clean -c ":luafile minimal-setup.lua"
```

### Backends

All the backends support rendering inside Tmux.

- `kitty` - best in class, works great and is very snappy
- `ueberzug` - backed by [ueberzugpp](https://github.com/jstkdng/ueberzugpp), supports any terminal, but has lower performance
  - Supports multiple images thanks to [@jstkdng](https://github.com/jstkdng/ueberzugpp/issues/74).

### Integrations

- `markdown` - uses [tree-sitter-markdown](https://github.com/MDeiml/tree-sitter-markdown) and supports any Markdown-based grammars (Quarto, VimWiki Markdown)
- `neorg` - uses [tree-sitter-norg](https://github.com/nvim-neorg/tree-sitter-norg) (also check https://github.com/nvim-neorg/neorg/issues/971)

You can configure where images are searched for on a per-integration basis by passing a function to
`resolve_image_path` as shown below:

```lua
require('image').setup({
  integrations = {
    markdown = {
      resolve_image_path = function(document_path, image_path, fallback)
        -- document_path is the path to the file that contains the image
        -- image_path is the potentially relative path to the image. for
        -- markdown it's `![](this text)`

        -- you can call the fallback function to get the default behavior
        return fallback(document_path, image_path)
      end,
    }
  }
})
```

## API

Check [types.lua](./lua/types.lua) for a better overview of how everything is modeled.

```lua
local api = require("image")

-- from a file (absolute path)
local image = api.from_file("/path/to/image.png", {
  id = "my_image_id", -- optional, defaults to a random string
  window = 1000, -- optional, binds image to a window and its bounds
  buffer = 1000, -- optional, binds image to a buffer (paired with window binding)
  with_virtual_padding = true, -- optional, pads vertically with extmarks, defaults to false

  -- optional, binds image to an extmark which it follows. Forced to be true when
  -- `with_virtual_padding` is true. defaults to false.
  inline = true,

  -- geometry (optional)
  x = 1,
  y = 1,
  width = 10,
  height = 10
})

-- from a URL
api.from_url("https://gist.ro/s/remote.png", {
    -- all the same options from above
}, function(img)
    -- do stuff with the image
end
)

image:render() -- render image
image:render(geometry) -- update image geometry and render it
image:clear()

image:move(x, y) -- move image
image:brightness(value) -- change brightness
image:saturation(value) -- change saturation
image:hue(value) -- change hue
```

---

### Thanks

- [@benlubas](https://github.com/benlubas) for their countless amazing contributions
- [@edluffy](https://github.com/edluffy) for [hologram.nvim](https://github.com/edluffy/hologram.nvim) - of which I borrowed a lot of code
- [@vhyrro](https://github.com/vhyrro) for their great ideas and [hologram.nvim fork](https://github.com/vhyrro/hologram.nvim) changes
- [@kovidgoyal](https://github.com/kovidgoyal) for [Kitty](https://github.com/kovidgoyal/kitty) - the program I spend most of my time in
- [@jstkdng](https://github.com/jstkdng) for [ueberzugpp](https://github.com/jstkdng/ueberzugpp) - the revived version of ueberzug

### The story behind

Some years ago, I took a trip to Emacs land for a few months to learn Elisp and also research what Org-mode is, how it works,
and look for features of interest for my workflow.
I already had my own document syntax, albeit a very simple one, hacked together with Vimscript and a lot
of Regex, and I was looking for ideas to improve it and build features on top of it.

I kept working on my [syntax](https://github.com/3rd/syslang) over the years, rewrote it many times, and today it's a proper Tree-sitter grammar,
that I use for all my needs, from second braining to managing my tasks and time.
It's helped me control my ADHD and be productive long before I was diagnosed, and it's still helping me be so much better than I'd be without it today.

One thing Emacs and Org-mode had that I liked was the ability to embed images in the document. Of course, we don't _"need"_ it, but... I really wanted to have images in my documents.

About 3 years ago, I made my [first attempt](https://www.reddit.com/r/neovim/comments/ieh7l4/im_building_an_image_plugin_and_need_some_help/) at solving this problem but didn't get far.
If you have similar interests, you might have seen the [vimage.nvim demo video](https://www.youtube.com/watch?v=cnt9mPOjrLg) on YouTube.

It was using [ueberzug](https://github.com/seebye/ueberzug), which is now dead. It was buggy and didn't handle things like window-relative positioning, attaching images to windows and buffers, folds, etc.

Kitty's graphics protocol was a thing, but it didn't work with Tmux, which I'll probably use forever or replace it with something of my own.

Now, things have changed, and I'm happy to announce that rendering images using [Kitty's graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol.html) from Neovim inside Tmux is working, and it's working pretty well!

My plan for this plugin is to support multiple backends, provide a few core integrations, and an easy-to-use API for other plugin authors to build on top of. There is a lot of logic that deals with positioning, cropping, bounds,
folds, extmarks, etc. that is painful and unrealistic to write from scratch for every plugin that wants to use images.
