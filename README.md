# 🖼️ image.nvim

This plugin adds image support to Neovim using [Kitty's Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/) or [ueberzugpp](https://github.com/jstkdng/ueberzugpp).
\
It works great with Kitty and Tmux, and it handles all the rendering complexity for you.

Join on Discord: https://discord.gg/GTwbCxBNgz

https://github.com/user-attachments/assets/0ae46acf-3240-446a-a458-7c7dfd03b9b7

We provide:

- A library for working with images
- A set of built-in integrations like Markdown and Neorg

Try it out quickly by downloading [minimal-setup.lua](./minimal-setup.lua) from the root of this repository and running `nvim --clean -c ":luafile minimal-setup.lua"`

## Getting started

### Dependencies

#### Rendering backend

We support two rendering backends, so first you need to set up one of these:

1. [Kitty](https://sw.kovidgoyal.net/kitty/) **(recommended)** >= 28.0 for the `kitty` backend
   - Has the best performance, native clipping, caching, etc.
   - You need to use Kitty or a terminal emulator that implements [Kitty's Graphics Protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/).
   - [WezTerm](https://github.com/wez/wezterm) implements it, but the performance is bad and it's not fully compliant.
     Most things work, but due to these issues it's not _officially supported_.
   - [Ghostty](https://ghostty.org/) not that much information about this yet! SUBJECT TO CHANGE
2. [Überzug++](https://github.com/jstkdng/ueberzugpp) for the `ueberzug` backend
   - Works with any terminal emulator.
   - Has much lower performance.
### Installing Überzug++
   <details>
   <summary>Pip</summary>

   ```sh
   sudo pip install ueberzugpp
   ```  

   </details>

   <details>
   <summary>Arch</summary>

   ```sh
   sudo pacman -Syu ueberzugpp
   ```

   </details>

   <details>
   <summary>Ubuntu/Debian/Fedora</summary>

   Follow instructions on [this link](https://software.opensuse.org/download.html?project=home%3Ajustkidding&package=ueberzugpp)

   </details>

   <details>
   <summary>macOS</summary>
      
   - Homebrew: `brew install jstkdng/programs/ueberzugpp`
   - **For some users** homebrew might install it into a weird location, so you have to add `$(brew --prefix)/lib` to `DYLD_FALLBACK_LIBRARY_PATH` by adding something like `export DYLD_FALLBACK_LIBRARY_PATH="$(brew -- prefix)/lib:$DYLD_FALLBACK_LIBRARY_PATH"` to your shell profile (probably `.zshrc` or `.bashrc`)

   </details>
   
   - Setup the configuration
      - Put this in `~/.config/ueberzugpp/config.json` (`the same for MacOS): <!-- 3rd change this to be correct if wrong, remove this comment if it's right! -->
      
         ```  
         {
             "layer": {
                 "silent": true,
                 "use-escape-codes": false,
                 "no-stdin": false,
                 "_comment": "Replace wayland in output with iterm2, if you want ssh support, x11 if you want to use it in xorg, sixel if you want to use sixels, chafa if you want to use the terminal colors.",
                 "_comment2": "Kitty is not mentioned in the list above, because image.nvim has native support for it.",
                 "output": "wayland" 
             }
         }
         ```
	 
      - You can remove the lines with `_comment` and `_comment2`, once you have tried every available option until one or more worked!

#### ImageMagick

We need to convert, scale, and crop images, and for that we use ImageMagick.
\
There are two ways we can do this, and you need to pick and follow the setup for the one you prefer.

1. Via FFI bindings (default) - using the `magick_rock` processor and the [magick Lua rock](https://github.com/leafo/magick)
   - Has slightly better performance.
   - Requires a working LuaRocks setup and building the magick rock.
2. Via CLI wrapping - using the `magick_cli` processor
   - Shells out to ImageMagick's CLI utilities like `identify` and `convert`.
   - Slightly scary in some scenarios as we could potentially pass untrusted input to a shell.
     We try to keep things secure, but this would be the main selling point of using the bindings instead.

For the `magick_cli` processor you need a regular installation of ImageMagick.
\
For the `magick_rock` processor you need to install the development version of ImageMagick.

<details>
<summary>NixOS</summary>

NixOS users need to install the `imagemagick` package.
For `magick_rock` you need to install `luajitPackages.magick` as well ([thanks](https://github.com/NixOS/nixpkgs/pull/243687) to [@donovanglover](https://github.com/donovanglover)).

- <details>
    <summary>Home Manager</summary>

  _thanks to [@wuliuqii](https://github.com/wuliuqii) in [#13](https://github.com/3rd/image.nvim/issues/13)_

  ```nix
  { pkgs, ... }:

  {
    programs.neovim = {
        enable = true;
        extraLuaPackages = ps: [ ps.magick ];
        extraPackages = [ pkgs.imagemagick ];
        # ... other config
    };
  }
  ```

  </details>

- <details>
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

<details>
<summary>Arch</summary>

```sh
sudo pacman -Syu imagemagick
```

</details>

<details>
<summary>Ubuntu/Debian</summary>

```sh
# for magick_cli
sudo apt install imagemagick
# for magick_rock
sudo apt install libmagickwand-dev
```

</details>

<details>
<summary>macOS</summary>

The setup is the same for both `magick_rock` and `magick_cli`:

- Homebrew: `brew install imagemagick`
  - **For some users** homebrew might install it into a weird location, so you have to add `$(brew --prefix)/lib` to `DYLD_FALLBACK_LIBRARY_PATH` by adding something like `export DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_FALLBACK_LIBRARY_PATH"` to your shell profile (probably `.zshrc` or `.bashrc`)
- MacPorts: `sudo port install imagemagick`
  - You must add `/opt/local/lib` to `DYLD_FALLBACK_LIBRARY_PATH`, similar to homebrew.

</details>

<details>
<summary>Fedora</summary>

```sh
# for magick_cli
sudo dnf install ImageMagick
# for magick_rock
sudo dnf install ImageMagick-devel
```

</details>

#### Tmux

This plugin will always have first class support for Tmux, to make it work make sure you:

- Use Tmux [>= 3.3](https://github.com/tmux/tmux/wiki/FAQ#:~:text=tmux%203.3%2C%20the-,allow%2Dpassthrough,-option%20must%20be)
- `set -gq allow-passthrough on`
- `set -g visual-activity off`

#### Other

- [cURL](https://github.com/curl/curl) for remote image support

### Plugin installation

After you've set up the dependencies, install the `image.nvim` plugin.

<details>
<summary><b>For magick_rock using Lazy >= v11.*</b></summary>

```lua
require("lazy").setup({
    rocks = {
        hererocks = true,  -- recommended if you do not have global installation of Lua 5.1.
    },
    specs = {
    	{
	    "3rd/image.nvim",
            opts = {}
    	},
    }
})
```

</details>

<details>
<summary><b>For magick_rock using Lazy < v11.x</b></summary>

It's recommended that you use [vhyrro/luarocks.nvim](https://github.com/vhyrro/luarocks.nvim) to install Lua rocks for Neovim while using lazy, but you can install them manually as well.

**With luarocks.nvim**
\
Please read the luarocks.nvim README, it currently has an external dependency.

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
    opts = {}
}
```

**Without luarocks.nvim**
\
You have to install the Lua rock manually.

1. Install [LuaRocks](https://luarocks.org/) on your system via your system package manager
2. Run `luarocks --local --lua-version=5.1 install magick`

```lua
-- Example for configuring Neovim to load user-installed installed Lua rocks:
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"

{
    "3rd/image.nvim",
    opts = {}
}
```

</details>

<details>
<summary><b>For magick_rock using Rocks.nvim</b></summary>

```
:Rocks install image.nvim
```

</details>

<details>
<summary><b>For magick_cli using Lazy</b></summary>

```lua
{
    "3rd/image.nvim",
    build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
    opts = {
	processor = "magick_cli",
    }
}
```

</details>

## Configuration

### Default configuration

```lua
require("image").setup({
  backend = "kitty",
  processor = "magick_rock", -- or "magick_cli"
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      floating_windows = false, -- if true, images will be rendered in floating markdown windows
      filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
    },
    neorg = {
      enabled = true,
      filetypes = { "norg" },
    },
    typst = {
      enabled = true,
      filetypes = { "typst" },
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
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
  editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
  tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
})
```

### Backends

All the backends support rendering inside Tmux.

- `kitty` - best in class, works great and is very snappy
- `ueberzug` - backed by [ueberzugpp](https://github.com/jstkdng/ueberzugpp), supports any terminal, but has lower performance
  - Supports multiple images thanks to [@jstkdng](https://github.com/jstkdng/ueberzugpp/issues/74).

### Integrations

- `markdown` - uses [tree-sitter-markdown](https://github.com/MDeiml/tree-sitter-markdown) and supports any Markdown-based grammars (Quarto, VimWiki Markdown)
- `neorg` - uses [tree-sitter-norg](https://github.com/nvim-neorg/tree-sitter-norg) (also check https://github.com/nvim-neorg/neorg/issues/971)
- `typst` - thanks to @etiennecollin (https://github.com/3rd/image.nvim/pull/223)
- `html` and `css` - thanks to @zuloo (https://github.com/3rd/image.nvim/pull/163)

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

Check https://github.com/3rd/image.nvim/issues/190#issuecomment-2378156235 for how to configure this for Obsidian.

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

-- create a report, also available as :ImageReport
require("image").create_report()
```

---

### Thank you

Deep thanks to the [awesome people](https://github.com/3rd/image.nvim/graphs/contributors) who have gifted their time and energy to this project, and to those who work on Neovim and the dependencies without which this would not be possible.

- [@benlubas](https://github.com/benlubas) for their countless amazing contributions
- [@edluffy](https://github.com/edluffy) for [hologram.nvim](https://github.com/edluffy/hologram.nvim) - of which I borrowed a lot of code
- [@vhyrro](https://github.com/vhyrro) for their great ideas and [hologram.nvim fork](https://github.com/vhyrro/hologram.nvim) changes
- [@kovidgoyal](https://github.com/kovidgoyal) for [Kitty](https://github.com/kovidgoyal/kitty) - the program I spend most of my time in
- [@jstkdng](https://github.com/jstkdng) for [ueberzugpp](https://github.com/jstkdng/ueberzugpp) - the revived version of ueberzug

![Analytics](https://repobeats.axiom.co/api/embed/fac3ac11abb0ea10e07af68d2ccdc20a1263325d.svg)

### The story behind

Some years ago, I took a trip to Emacs land for a few months to learn Elisp and also research what Org-mode is, how it works, and look for features of interest for my workflow.

I already had my own document syntax, albeit a very simple one, hacked together with Vimscript and a lot of Regex, and I was looking for ideas to improve it and build features on top of it.

I kept working on my [syntax](https://github.com/3rd/syslang) over the years, rewrote it many times, and today it's a proper Tree-sitter grammar, that I use for all my needs, from second braining to managing my tasks and time. It's helped me control my ADHD and be productive long before I was diagnosed, and it's still helping me be so much better than I'd be without it today.

One thing Emacs and Org-mode had that I liked was the ability to embed images in the document. Of course, we don't _"need"_ it, but... I really wanted to have images in my documents.

About 3 years ago, I made my [first attempt](https://www.reddit.com/r/neovim/comments/ieh7l4/im_building_an_image_plugin_and_need_some_help/) at solving this problem but didn't get far. If you have similar interests, you might have seen the [vimage.nvim demo video](https://www.youtube.com/watch?v=cnt9mPOjrLg) on YouTube.

It was using [ueberzug](https://github.com/seebye/ueberzug), which is now dead. It was buggy and didn't handle things like window-relative positioning, attaching images to windows and buffers, folds, etc.

Kitty's graphics protocol was a thing, but it didn't work with Tmux, which I'll probably use forever or replace it with something of my own.

Now, things have changed, and I'm happy to announce that rendering images using [Kitty's graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol.html) from Neovim inside Tmux is working, and it's working pretty well!
