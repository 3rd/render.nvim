# Changelog

## [1.4.0](https://github.com/3rd/image.nvim/compare/v1.3.0...v1.4.0) (2025-01-17)


### Features

* add floating_windows integration option ([208661b](https://github.com/3rd/image.nvim/commit/208661b7b1a38c373d15a1bba4bfcc61a6a261ba))
* add rockspec to avoid needs of extra plugins on Lazy >= v11 ([94319cd](https://github.com/3rd/image.nvim/commit/94319cdafec62cd5b3ac1448ed1aae1bbe731f45))
* add unescaped image path fallback ([5f8fcec](https://github.com/3rd/image.nvim/commit/5f8fceca2d1be96a45b81de21c2f98bf6084fb34))
* allow larger-than-window images and upscaling ([7b48e8c](https://github.com/3rd/image.nvim/commit/7b48e8c04872a4718baca6fd3cd6a39c94e4dd59))
* allow passing max_{width,height}_window_percentage to image factory ([d5a5166](https://github.com/3rd/image.nvim/commit/d5a51669318f1e3cb5c0eb4c89b670715543886c))
* clear/rerender images on VimSuspend/VimResume ([7f61c19](https://github.com/3rd/image.nvim/commit/7f61c1940a8b072ca47a28928d2375dc1e11f464))
* curl always redirect ([56ddfa2](https://github.com/3rd/image.nvim/commit/56ddfa21270160126c26bc98133c0f7755d91511))
* generalize image processors and add magick_cli and :ImageReport ([72fce55](https://github.com/3rd/image.nvim/commit/72fce550e609e41bb18e047bf615312099539504))
* handle external source image changes ([2d0be8c](https://github.com/3rd/image.nvim/commit/2d0be8c7ea337e58abcfe43dca030703803a0e10))
* image clipping on scroll ([79e4c59](https://github.com/3rd/image.nvim/commit/79e4c59cb886f549baa416889a195fa672781c5a))
* try to detect format/size in lua before falling back to magick ([17ab287](https://github.com/3rd/image.nvim/commit/17ab287afdbb748246885094c15cfa16b44d4d60))


### Bug Fixes

* add missing events for hijack mode ([b991fc7](https://github.com/3rd/image.nvim/commit/b991fc7f845bc6ab40c6ec00b39750dcd5190010))
* bail early out of nvim_set_decoration_provider ([6fb2b84](https://github.com/3rd/image.nvim/commit/6fb2b84a739d92b781bba5f59f2678ea047332a9))
* disable rockspec until we fix https://github.com/3rd/image.nvim/issues/191 ([61c7651](https://github.com/3rd/image.nvim/commit/61c76515cfc3cdac8123ece9e9761b20c3dc1315))
* guard magick check ([98a8999](https://github.com/3rd/image.nvim/commit/98a8999b362a15c189b07261237247911c96c319))
* handle clipping for images with virtual padding ([6f7e2ed](https://github.com/3rd/image.nvim/commit/6f7e2ed3840a703d4e0a14a351904b4928bcb1ad))
* images not rendered when on the first line ([25676de](https://github.com/3rd/image.nvim/commit/25676deed3d5cba3d8dda0f2a0e9c0b71a4aaab6))
* **kitty:** image shown when switching to different tmux session [#198](https://github.com/3rd/image.nvim/issues/198) ([bcdc1e3](https://github.com/3rd/image.nvim/commit/bcdc1e3676d6e48d569f8e45db7278a93e944dbf))
* more reliably hijack buffer ([d3914da](https://github.com/3rd/image.nvim/commit/d3914daaf47b38c024778890fd5c6f1ecdb492be))
* **readme:** Fix typo in pacman command ([47c9470](https://github.com/3rd/image.nvim/commit/47c947061c93e19aa9dba5cf2dbf374a4b46811e))
* remove shell substitution for compatibility ([5c5df4a](https://github.com/3rd/image.nvim/commit/5c5df4ac935e6b95543b46e05b79d68483195c78))
* session clear & forced rerender on focusgained ([3f0cbb5](https://github.com/3rd/image.nvim/commit/3f0cbb5b540429ebae13e3229c0f75729f654b18))
* text change watcher not working when switching to buffer ([f380265](https://github.com/3rd/image.nvim/commit/f380265e81443f590f29bbee3d7b4a71ca2b93fa))

## [1.3.0](https://github.com/3rd/image.nvim/compare/v1.2.0...v1.3.0) (2024-05-14)


### Features

* configurable resolve_image_path function ([6ab77ff](https://github.com/3rd/image.nvim/commit/6ab77ffda4ac0825a9b49e5580da261e74a577ac))
* include the magick error in the "rock not found" message ([13f56f4](https://github.com/3rd/image.nvim/commit/13f56f4eea294f190db8c67d4c8045d3be608f4b))
* namespace integration images ([ec57744](https://github.com/3rd/image.nvim/commit/ec577441edca399c43d77b522870dbd7b9cd38b8))
* shortcut link imgs in md doc integration ([af1fb0c](https://github.com/3rd/image.nvim/commit/af1fb0cf3aaae48c5a25afb4152f94cb46e344e9))
* sync image positions to external extmark changes ([c53bbc4](https://github.com/3rd/image.nvim/commit/c53bbc41debf42e6470235c4fef9868f6be20c12))
* track col position for extmarks ([d24d498](https://github.com/3rd/image.nvim/commit/d24d498cdb020bb87d629263e89f25767b6c73c9))
* use sha256 for hashing ([4d7ae21](https://github.com/3rd/image.nvim/commit/4d7ae2162ace0f7028e60148ba6fecd78659a994))


### Bug Fixes

* account for char with multiple conceal hl ([a61323f](https://github.com/3rd/image.nvim/commit/a61323f72c2533e4d85a3fac1539868c6083f934))
* account for extmarks/conceal for inline imgs ([be2d94a](https://github.com/3rd/image.nvim/commit/be2d94a6e0143bb276b474c6fa58bebcb64a5f8a))
* add missing scrollview_sign ft to overlap exceptions ([895ff42](https://github.com/3rd/image.nvim/commit/895ff42de4c9682f1eafe0ce4913ef66e498fc4d))
* add scrollview to default non-overlapping filetypes ([bf168f8](https://github.com/3rd/image.nvim/commit/bf168f8c4a6ec7b6d892defb62607c81d88b86d9))
* auto-clear/re-render on tab switch ([95a3afd](https://github.com/3rd/image.nvim/commit/95a3afd192931eac58703c269164aae989cbfd09))
* better clearing, hijack cache rerender, resize ([77df64a](https://github.com/3rd/image.nvim/commit/77df64af37ff68a1f593aa4f79b42b1388479239))
* don't look at extmarks on line below ([9cc4e13](https://github.com/3rd/image.nvim/commit/9cc4e13ccd20ccc142110c495a88d80df47e7ce6))
* extend jpeg signatures ([2cb0a10](https://github.com/3rd/image.nvim/commit/2cb0a100f8b1311ca2f373927b2f3aed61684540))
* get_images api https://github.com/3rd/image.nvim/issues/111 ([2090055](https://github.com/3rd/image.nvim/commit/2090055394d5c8efb5f23143cc2f3d9fac68a61e))
* hardcode markdown parser (fixes vimwiki) ([0dd8bdb](https://github.com/3rd/image.nvim/commit/0dd8bdbb8855bc98c534a902c91dc9eddb8155b1))
* hash urls/ids for temp paths ([e3d2cc1](https://github.com/3rd/image.nvim/commit/e3d2cc1f88588192a119206ff912279b57954ed4))
* namespaces not set on images ([088c2ed](https://github.com/3rd/image.nvim/commit/088c2ed65d05aea12389ea76b96bb2bfe6f964d8))
* nil check extmark_y ([f40f1d4](https://github.com/3rd/image.nvim/commit/f40f1d445e75d8d9101fe44e2df962a202b79695))
* padded images cause lower images to rerender ([5cb5b0e](https://github.com/3rd/image.nvim/commit/5cb5b0e8dc3a10ff5946efbdb06881e0b475b28c))
* re-use file descriptor for jpeg check ([402ff91](https://github.com/3rd/image.nvim/commit/402ff916a17f86fb6542886ad0d553f5d77cf22f))

## [1.2.0](https://github.com/3rd/image.nvim/compare/v1.1.0...v1.2.0) (2023-12-25)


### Features

* add svg to render list ([147bbe6](https://github.com/3rd/image.nvim/commit/147bbe661bdec4a16a93fbd1f08a43040c363942))
* hijack ft & expose API https://github.com/3rd/image.nvim/issues/61 ([6598813](https://github.com/3rd/image.nvim/commit/6598813b4c4e395eba0b2217cd6458aaa58b897f))
* hijack image file patterns https://github.com/3rd/image.nvim/issues/56 ([7b475c4](https://github.com/3rd/image.nvim/commit/7b475c4cafb0ab4435defb830c0160451701402f))
* only attempt to render a fixed list of image formats ([4c1c903](https://github.com/3rd/image.nvim/commit/4c1c903268b42a5b83caf229ddda7014a6a2e0bd))
* re-use already converted images ([e9fd310](https://github.com/3rd/image.nvim/commit/e9fd31074c9cfd4ca2759313c560247fe5dada1d))
* support split events for hijacking and prevent useless loading https://github.com/3rd/image.nvim/issues/60 ([d7ba5d3](https://github.com/3rd/image.nvim/commit/d7ba5d3b2a13dc22e7e464d9be066a29b3abddf3))


### Bug Fixes

* clear images that were not rendered ([c91d47c](https://github.com/3rd/image.nvim/commit/c91d47c8e69a0959b29117f3fb86ae6b8f19efec))
* **document:** ignore remote image loading errors https://github.com/3rd/image.nvim/issues/65 ([1650ecc](https://github.com/3rd/image.nvim/commit/1650eccca5b0d071d1305c17646ad16693987796))
* don't clear images not attached to windows on window close ([4d1dd5d](https://github.com/3rd/image.nvim/commit/4d1dd5ddc63b37e5af303af0a3a8ed752d43a95c))
* images rendering below extmarks on same line ([0d3ab85](https://github.com/3rd/image.nvim/commit/0d3ab852f55a9080a045756bd9900868b19726cd))
* **kitty:** don't send unicode placeholder flag unnecessary ([7aaad09](https://github.com/3rd/image.nvim/commit/7aaad09f53c620fd61074c3b05940db861dd606c))
* markdown parsing error (also parsing might be broken in new files) ([1cb60be](https://github.com/3rd/image.nvim/commit/1cb60be1cdc108e3a3b09cb0ed115ef75ce51320))
* max width/height should not depend on scroll position ([04ad8fe](https://github.com/3rd/image.nvim/commit/04ad8fe861ded0809f2997acddee1a9d37de8f89))
* min 1 cell for width/height when inferring ([8ff8abc](https://github.com/3rd/image.nvim/commit/8ff8abca008ba193b1ed2c38fa93b1517b82de8a))
* **neorg:** resolve workspace notation with image files ([98cd990](https://github.com/3rd/image.nvim/commit/98cd990967e9de94a6ffa506c8127611bfa445b1))
* parse markdown buffer with markdown parser and get inlines as children ([984a7fa](https://github.com/3rd/image.nvim/commit/984a7fac438fc3d15da5f16d7dc6383b77ca8203))
* performance issues due to tmux+ssh hack https://github.com/3rd/image.nvim/issues/89 ([2aad3ad](https://github.com/3rd/image.nvim/commit/2aad3ad35e136240a7b2fb53a50d87358f867463))
* position relative nearby virtual text ([4d18722](https://github.com/3rd/image.nvim/commit/4d18722d82e9f3a5983c5a2d640fbf9973688906))
* process events for all windows when checking for overlaps ([8637d24](https://github.com/3rd/image.nvim/commit/8637d24fd36211bda5e4b7abef9a15fdf44a40a1))
* re-transmit all images after resize and force rerender ([4fee87e](https://github.com/3rd/image.nvim/commit/4fee87e4d63dfe35c430c950cae63acdaf5e6785))
* rendering images below folded extmarks ([8bcf828](https://github.com/3rd/image.nvim/commit/8bcf828cd310794f437cde745e7cf39e3d498efc))
* scale aspect ratio correctly, fix tmux split (https://github.com/3rd/image.nvim/issues/64) ([72bbf46](https://github.com/3rd/image.nvim/commit/72bbf46977aec8a25d9b515fe12011c639543727))
* stacked images ([44c0a1c](https://github.com/3rd/image.nvim/commit/44c0a1cbcab8276beeac6d67efa449816e5731f5))
* tmux passthrough check broken by https://github.com/NixOS/nixpkgs/issues/261777 ([431235a](https://github.com/3rd/image.nvim/commit/431235a5f5cfc3a4c17c600a8ac88257f99de3d6))
* trigger hijacking on BufWinEnter https://github.com/3rd/image.nvim/issues/60 ([80906aa](https://github.com/3rd/image.nvim/commit/80906aa014024fdc47d437df2d724328d33d3f15))

## [1.1.0](https://github.com/3rd/image.nvim/compare/v1.0.0...v1.1.0) (2023-10-20)


### Features

* add editor_only_render_when_focused option ([133926c](https://github.com/3rd/image.nvim/commit/133926c01bb5160b6ff26c37891e7d8a1d73528f))
* add tmux_show_only_in_active_window option ([60d7fc6](https://github.com/3rd/image.nvim/commit/60d7fc61ff41ca9951101c245505b3a03e3eb8cb))
* auto-handle hiding/showing the images on tmux window switch ([3fbe47d](https://github.com/3rd/image.nvim/commit/3fbe47d7e1b5d18eff5fb118ee232047ac3f823d))


### Bug Fixes

* better text change handling using nvim_buf_attach ([33f7234](https://github.com/3rd/image.nvim/commit/33f72342df52af2864ec6e4a14099267cdc01b61))
* bug causing double extmark clearing weirdness ([a3e0b9f](https://github.com/3rd/image.nvim/commit/a3e0b9f0395f32d6e6c1fd8a032600ab07f8ff2b))
* clear / rerender images on BufLeave ([471eca9](https://github.com/3rd/image.nvim/commit/471eca9a895e065a16761f708ba46911987516d1))
* clear images when closing a twin window ([bd95cc9](https://github.com/3rd/image.nvim/commit/bd95cc9c13ae61b8e2453a0234250ea782b84ce7))
* commit error ([aa3004e](https://github.com/3rd/image.nvim/commit/aa3004e3e695f16166cd6c866e25a0a9ea1a51da))
* disable decoration provider handling on focus lost (when needed) ([725eccb](https://github.com/3rd/image.nvim/commit/725eccb7f50c82c9b028b3fbb461b0d2b198ef01))
* document integrations shouldn't care about resizing ([7234469](https://github.com/3rd/image.nvim/commit/7234469ce44dca9d3a3124c17daea0e9810f0ff9))
* **document:** queue images for rendering after clearing the old ones ([ae351ca](https://github.com/3rd/image.nvim/commit/ae351ca5134450b64d81e02c3d57580016b1a40b))
* **document:** rerender images when text changes in insert mode ([fb929d0](https://github.com/3rd/image.nvim/commit/fb929d0fd5a0db2983c1ad0c537e4f063ef06c45))
* guard against extmark creation errors in decoration provider ([9bf46c1](https://github.com/3rd/image.nvim/commit/9bf46c14fa1b3318e99213df5ec01272584a5010))
* plugin breaking visual mode actions and decorator optimizations ([440aee9](https://github.com/3rd/image.nvim/commit/440aee9071697b5ac1ac2e69a61c1187311c2cce))
* rendering width/height inference bug ([6e597f8](https://github.com/3rd/image.nvim/commit/6e597f84b5242e18133627c26743bcd0734de1ca))
* tmux same-window check ([2db85d0](https://github.com/3rd/image.nvim/commit/2db85d0b84dffde074622be1989a4d234b307577))

## 1.0.0 (2023-10-08)


### Features

* add "height-from-empty-lines" sizing strategy to markdown ([6412397](https://github.com/3rd/image.nvim/commit/6412397a77b34d2096372e84d751631338e24df6))
* add initial implementation for kitty unicode placeholders and debugging ([e65ca7c](https://github.com/3rd/image.nvim/commit/e65ca7c0806d9f1ecd3c7dd00c70aa3780273749))
* add Neorg integration ([069eb23](https://github.com/3rd/image.nvim/commit/069eb2372dea2273685b367d89347ec74ec772c9))
* add option to only render the image under cursor for markdown and neorg (https://github.com/3rd/image.nvim/discussions/14) ([1abfecb](https://github.com/3rd/image.nvim/commit/1abfecb67aeb103b0d597f1e8098995f2a72934d))
* add remote image support and integrate it with markdown ([7023c7d](https://github.com/3rd/image.nvim/commit/7023c7d10a78f154dc1f501c9f511aad356270ec))
* allow kitty to handle cropping in default mode for better perf ([814af48](https://github.com/3rd/image.nvim/commit/814af48b934d4f01d16f4b1f0974d495fed1b878))
* bootstrap kitty backend based on hologram.nvim ([a28df8b](https://github.com/3rd/image.nvim/commit/a28df8b844a791da3b6f9b3e824886f88bf692b5))
* cache intermediary converted, resized, and cropped image variants ([961e5a6](https://github.com/3rd/image.nvim/commit/961e5a68998dd76bf5e25ae2d96fcf3bb1ee22ae))
* compute window masks and toggle overlapped window images ([e524050](https://github.com/3rd/image.nvim/commit/e5240500b82cfc396bfd7e975da3cd3bd5f763b9))
* export basic rendering operations render() and clear() ([4515796](https://github.com/3rd/image.nvim/commit/4515796c3bdcb2e9369aee0ca0ea39027f7b742b))
* extract cropping into renderer and handle with magick ([573e057](https://github.com/3rd/image.nvim/commit/573e0575313c14558be08db72a02b1b29f3ad73d))
* genesis ([16d34a0](https://github.com/3rd/image.nvim/commit/16d34a049d894beacbbd8a2770c1831c248ecc17))
* handle bounds separately in backends, multi-split support ([c45a050](https://github.com/3rd/image.nvim/commit/c45a0504cafe38ff98004e76c046c1c1e286908f))
* handle extmark scroll, allow editing and preview in markdown at the same time, fix kitty clear ([31d12e0](https://github.com/3rd/image.nvim/commit/31d12e0210a51ff9f0e38ae2fd5cf74ac3ff7088))
* handle folds ([e42ea8c](https://github.com/3rd/image.nvim/commit/e42ea8c032b368aaf826c5c32498dbb86e22d1be))
* kitty vertical split bottom crop ([445fc24](https://github.com/3rd/image.nvim/commit/445fc24557d07361fac4338419e075845f121d9f))
* markdown - add clear_in_insert_mode option ([c4d14a2](https://github.com/3rd/image.nvim/commit/c4d14a2a5efc17d7c7f6afc12f27872de2d254a3))
* markdown - add toggle for remote image downloads ([dbf1f15](https://github.com/3rd/image.nvim/commit/dbf1f1521560bc20f8e89f6f418622d26fd7b260))
* markdown - resolve relative images ([dd93b11](https://github.com/3rd/image.nvim/commit/dd93b11164f046b0570c461b82de4d890804499a))
* move to imagemagick for image handling ([3dbb7f4](https://github.com/3rd/image.nvim/commit/3dbb7f45be8af7071cf24ad20d2f56b04ae74d0d))
* remote url support for neorg (images must be alone on lines and start with .image) ([7f2edec](https://github.com/3rd/image.nvim/commit/7f2edec4c11f24529b8124ce49bdae3a9969e6bd))
* rework image API and add support for magick manipulations ([4fbc195](https://github.com/3rd/image.nvim/commit/4fbc1951c45756116bf003fcfbfb8e2b5478c3c3))
* rewrite most things, restructure API, extmarks, multi-window support, auto-clear,  ueberzug++ ([cd58741](https://github.com/3rd/image.nvim/commit/cd587411c85d1e11d1c871748bf5f14e9d5a5940))
* scale down big images before rendering instead of cropping right and fix rendering bug ([6972ff4](https://github.com/3rd/image.nvim/commit/6972ff44ed784921fda0f1706ba1fae61051ea8e))
* tmux + kitty (normal) rendering ([4399f69](https://github.com/3rd/image.nvim/commit/4399f69043df82cc491168b0260d9c071aab4682))
* use atomic screen updates for kitty ([6623c7e](https://github.com/3rd/image.nvim/commit/6623c7e314579cc5e6ff98472757e29e75491019))
* window-relative rendering, refactor general structure, types, many things ([2134ca7](https://github.com/3rd/image.nvim/commit/2134ca79a6af8aa7ab97719acf6d841f5b008b75))


### Bug Fixes

* add url to image id ([2c1e1a6](https://github.com/3rd/image.nvim/commit/2c1e1a6b79b9759a873bf5189e4c1ae937a53d2e))
* bail early when checking for images to clear if there are no images ([c891ad8](https://github.com/3rd/image.nvim/commit/c891ad866045cba6fc84dd22423589ce3d7e798a))
* bottom cropping ([90c5183](https://github.com/3rd/image.nvim/commit/90c51839a0bf05a209b78fa2b6858228e800b3e9))
* cache TIOCGWINSZ ([847f5d6](https://github.com/3rd/image.nvim/commit/847f5d6d37f0607a29485944768ff3ff6a6b1952))
* check for ft in markdown autocommands ([9aa67f6](https://github.com/3rd/image.nvim/commit/9aa67f6582f6384b3b18cfeeb83ce52888bb8d29))
* check that window and buffer are valid & init namespace directly ([ef15a6d](https://github.com/3rd/image.nvim/commit/ef15a6d5f2e93b635dcddf4de1f76c706e3f4d0f))
* clear images even if they're not rendered ([ddf4b58](https://github.com/3rd/image.nvim/commit/ddf4b58bec33b46d319ee1392382982777a08ffb))
* clear images on window close ([692bcb7](https://github.com/3rd/image.nvim/commit/692bcb7bb1ed29f9c8b7b8524f150180b10f6cf1))
* destroy magick image after crop ([8f7a054](https://github.com/3rd/image.nvim/commit/8f7a054bafa97eb0e77774a9e11c3d0e2d0b01fb))
* don't fetch images in insert mode ([16f5407](https://github.com/3rd/image.nvim/commit/16f54077ca91fa8c4d1239cc3c1b6663dd169092))
* don't wrap backend and integration load errors ([ae0bbc4](https://github.com/3rd/image.nvim/commit/ae0bbc408bddf022689c2239c43ef65c8863e802))
* fix images not working if initially inside folds & extmark tweaks ([03f4eb7](https://github.com/3rd/image.nvim/commit/03f4eb748e311aaf3af7f8bb2211c60b59160963))
* handle folds when having less lines than window height ([d2a69cd](https://github.com/3rd/image.nvim/commit/d2a69cd4222297d32671d69f27fd6722688d3646))
* handle images with zero width/height ([e4d3c4c](https://github.com/3rd/image.nvim/commit/e4d3c4c405f96975bcf89997c068f1d0ce9115cb))
* increase default tmux write delay ([b8b9633](https://github.com/3rd/image.nvim/commit/b8b9633c6fc5c5e40360ff615bfbb55d84c5a537))
* kitty - clear images on exit ([2561f01](https://github.com/3rd/image.nvim/commit/2561f01bcf44c6f4014c7c92da3225f78fda0c44))
* kitty - re-transmit images after vim resize ([3037f1d](https://github.com/3rd/image.nvim/commit/3037f1d2d8f004d69b421bf1f2267e55f2ac975b))
* kitty - save some cursor movements ([11a5452](https://github.com/3rd/image.nvim/commit/11a54524b9e0611f2646bb41cd38b7c12096118e))
* leftover ([8f03d32](https://github.com/3rd/image.nvim/commit/8f03d32aa75f3ad4f0262320024092fb326f58d6))
* markdown - follow clear_in_insert_mode when editing in insert mode ([a15734e](https://github.com/3rd/image.nvim/commit/a15734e70bf66e920223656d835a37e1cb44f822))
* markdown - ignore loading errors ([dec5c4c](https://github.com/3rd/image.nvim/commit/dec5c4c8a8d3355798ba65bc35f8e0c20d4794e9))
* only cache remote image urls, fixes same remote image in multiple splits ([1738f08](https://github.com/3rd/image.nvim/commit/1738f08e14730074d25d29eaf0c19882218d1b08))
* optimize kitty rendering (non-cropped) ([52b25c3](https://github.com/3rd/image.nvim/commit/52b25c375ed14de3948d4ff522705eeb0ee4d3df))
* prevent unnecessary rerenders ([c7d977c](https://github.com/3rd/image.nvim/commit/c7d977c6b4e2db5d76baf60fd7020f71a66f1a40))
* prevent unnecessary rerenders and recrop previous images on new splits ([b2ac03f](https://github.com/3rd/image.nvim/commit/b2ac03f352958c009534b5c6b9f12b3a9c51793a))
* prevent useless rerenders and clean-up ([4d1ab88](https://github.com/3rd/image.nvim/commit/4d1ab88049ca1dae47765a0c36131d6037ceb8a6))
* remove extmark map entry when clearing image ([4a68eda](https://github.com/3rd/image.nvim/commit/4a68eda54ef695f6ec025f874f67e9958ddff1b8))
* remove tmux cursor delay and silence winclosed error ([0b2dae8](https://github.com/3rd/image.nvim/commit/0b2dae85a5150a13b7f2ef7a4b20bf8faa6dea07))
* rendering errors when geometry is not provided, limit vspace y ([b6057c5](https://github.com/3rd/image.nvim/commit/b6057c5022a08e3ed37b6d8c26be63661d1cc482))
* rendering glitches and handle buffer change clearing through decoration provider ([5979f47](https://github.com/3rd/image.nvim/commit/5979f47e0510d266acbe838415f994d53497662b))
* replace '/' with '-' in base64 encode ([1e0a270](https://github.com/3rd/image.nvim/commit/1e0a27024f19c5e1f5307c449380f54888301c5e))
* rerender affected images after updating extmarks ([b5e8b75](https://github.com/3rd/image.nvim/commit/b5e8b756d0bcc4756e41684667c541cd3afd6c7f))
* rerender images below the current one after adding extmark ([093ef13](https://github.com/3rd/image.nvim/commit/093ef13a4f9920fd7a78f83b7b6dcf9b8cb672b3))
* restore winscrolled handling ([721bc43](https://github.com/3rd/image.nvim/commit/721bc43fe13287e9745903740cb6c5d9da8e0b76))
* track and reset crop, fix vertical screen bounds ([affcc53](https://github.com/3rd/image.nvim/commit/affcc53023bcc784a98f1daa945f1898f4a0a8c2))
* ueberzug - prevent useless clear ([bffa411](https://github.com/3rd/image.nvim/commit/bffa41142dce95c20fefa45809c13c9d9c4e9925))
* update kitty backend to the new structure ([3ca9bf5](https://github.com/3rd/image.nvim/commit/3ca9bf5bd4651d4451d121f1e538ad2fa46ef126))
* wrong positioning, window/gutter offset math, ty https://github.com/3rd/image.nvim/pull/6 ([c957678](https://github.com/3rd/image.nvim/commit/c9576783d2eac3594fc6d264001e10bec60444b9))


### Performance Improvements

* optimize rendering and always use shallow delete for kitty images ([05679fa](https://github.com/3rd/image.nvim/commit/05679faad71bb0dd6475b539657d02c5dd6e3322))
* re-use fixed paths for source, resized, and cropped image variants ([7a98960](https://github.com/3rd/image.nvim/commit/7a98960aace23bf845b39b89d64f52f26bec01c1))
* split pre-processing caching into resize and crop ([d3b3246](https://github.com/3rd/image.nvim/commit/d3b32462e252f448c994ba291c1e741df3bebabb))
