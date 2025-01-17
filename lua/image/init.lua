local utils = require("image/utils")
local processors = require("image/processors")
local report = require("image/report")

---@type Options
local default_options = {
  -- backend = "ueberzug",
  backend = "kitty",
  processor = "magick_rock",
  integrations = {
    markdown = {
      enabled = true,
    },
    typst = {
      enabled = true,
    },
    neorg = {
      enabled = true,
    },
    syslang = {
      enabled = true,
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
  max_width_window_percentage = 100,
  max_height_window_percentage = 50,
  scale_factor = 1.0,
  kitty_method = "normal",
  window_overlap_clear_enabled = false,
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
  editor_only_render_when_focused = false,
  tmux_show_only_in_active_window = false,
  hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
}

---@type State
local state = {
  ---@diagnostic disable-next-line: assign-type-mismatch
  backend = nil,
  ---@diagnostic disable-next-line: assign-type-mismatch
  processor = nil,
  options = default_options,
  images = {},
  extmarks_namespace = vim.api.nvim_create_namespace("image.nvim"),
  remote_cache = {},
  tmp_dir = vim.fn.tempname(),
  disable_decorator_handling = false,
  hijacked_win_buf_images = {},
}

---@type API
---@diagnostic disable-next-line: missing-fields
local api = {}

---@param options Options
api.setup = function(options)
  local opts = vim.tbl_deep_extend("force", default_options, options or {})
  state.options = opts

  vim.schedule(function()
    if opts.processor == "magick_rock" then
      local magick = require("image/magick")
      -- check that magick is available
      if not magick.has_magick then
        vim.api.nvim_err_writeln(
          "image.nvim: magick rock not found, please install it and restart your editor. Error: "
            .. vim.inspect(magick.magick)
        )
        return
      end
    end
  end)

  -- load processor
  state.processor = processors.get_processor(opts.processor)

  -- load backend
  local backend = require("image/backends/" .. opts.backend)
  if type(backend.setup) == "function" then backend.setup(state) end
  state.backend = backend

  -- load integrations
  for integration_name, integration_options in pairs(opts.integrations) do
    if integration_options.enabled then
      local integration = require("image/integrations/" .. integration_name)
      if type(integration.setup) == "function" then integration.setup(api, integration_options, state) end
    end
  end

  -- create tmp dir
  vim.fn.mkdir(state.tmp_dir, "p")

  -- handle folds / scroll extra
  ---@type table<number, { topline: number, botline: number, bufnr: number, height: number; folded_lines: number }>
  local window_history = {}
  vim.api.nvim_set_decoration_provider(state.extmarks_namespace, {
    on_win = function(_, winid, bufnr, topline, botline)
      -- bail if decorator handling is disabled
      if state.disable_decorator_handling then return false end

      -- bail if not in normal mode, there's a weird behavior where in visual mode this callback gets called CONTINUOUSLY
      if vim.api.nvim_get_mode().mode ~= "n" then return false end

      if not vim.api.nvim_win_is_valid(winid) then return false end
      if not vim.api.nvim_buf_is_valid(bufnr) then return false end

      -- bail if there are no images
      local all_images = api.get_images()
      if #all_images == 0 then return false end

      -- toggle images in overlapped windows
      if state.options.window_overlap_clear_enabled then
        vim.schedule(function()
          local windows = utils.window.get_windows({
            normal = true,
            floating = true,
            with_masks = true,
            ignore_masking_filetypes = state.options.window_overlap_clear_ft_ignore,
          })

          for _, current_window in ipairs(windows) do
            local cur_win_images = api.get_images({ window = current_window.id, buffer = bufnr })
            if #current_window.masks > 0 then
              for _, current_image in ipairs(cur_win_images) do
                current_image:clear(true)
              end
            else
              for _, current_image in ipairs(cur_win_images) do
                if not current_image.is_rendered then current_image:render() end
              end
            end
          end
        end)
      end

      -- bail if there are no images tied to this window and buffer pair
      local images = api.get_images({ window = winid, buffer = bufnr })
      if #images == 0 then return false end

      -- get current window
      local window = utils.window.get_window(winid)
      if not window then return false end

      -- get history entry or init
      local prev = window_history[winid]
      if not prev then
        window_history[winid] = { topline = topline, botline = botline, bufnr = bufnr }
        return false
      end

      local height = vim.api.nvim_win_get_height(winid)
      local needs_clear = false
      local needs_rerender = false

      -- clear if buffer changed
      needs_clear = prev.bufnr ~= bufnr

      -- rerender if height, topline, or botline changed
      needs_rerender = prev.topline ~= topline or prev.botline ~= botline or prev.height ~= height

      -- rerender if the amount of folded lines changed
      local folded_lines = 0
      local i = 1
      while i < botline do
        local fold_start, fold_end = vim.fn.foldclosed(i), vim.fn.foldclosedend(i)
        if fold_start ~= -1 and fold_end ~= -1 then
          folded_lines = folded_lines + (fold_end - fold_start)
          i = fold_end + 1
        else
          i = i + 1
        end
      end
      if prev.folded_lines ~= folded_lines then needs_rerender = true end

      -- store new state
      window_history[winid] =
        { topline = topline, botline = botline, bufnr = bufnr, height = height, folded_lines = folded_lines }

      -- execute deferred clear / rerender
      -- utils.debug("needs_clear", needs_clear, "needs_rerender", needs_rerender)
      vim.schedule(function()
        if needs_clear then
          for _, curr in ipairs(api.get_images({ window = winid, buffer = prev.bufnr })) do
            curr:clear(true)
          end
        elseif needs_rerender then
          for _, curr in ipairs(api.get_images({ window = winid, buffer = bufnr })) do
            curr:render()
          end
        end
      end)

      return false
    end,
  })

  -- setup autocommands
  local group = vim.api.nvim_create_augroup("image.nvim", { clear = true })

  -- auto-clear on buffer / window close
  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed", "TabEnter" }, {
    group = group,
    callback = function() -- auto-clear images when windows and buffers change
      vim.schedule(function()
        local images = api.get_images()

        local windows_in_current_tab = vim.api.nvim_tabpage_list_wins(0)
        local windows_in_current_tab_map = {}
        for _, current_window in ipairs(windows_in_current_tab) do
          windows_in_current_tab_map[current_window] = true
        end

        for _, current_image in ipairs(images) do
          if current_image.window then
            local window_ok, is_valid_window = pcall(vim.api.nvim_win_is_valid, current_image.window)
            if not window_ok or not is_valid_window then
              current_image:clear()
              return
            end

            local is_window_in_current_tab = windows_in_current_tab_map[current_image.window]
            if not is_window_in_current_tab then
              current_image:clear()
              return
            end

            if current_image.buffer then
              local buf_ok, is_valid_buffer = pcall(vim.api.nvim_buf_is_valid, current_image.buffer)
              if not buf_ok or not is_valid_buffer then
                current_image:clear()
                return
              end

              local is_buffer_in_window = vim.api.nvim_win_get_buf(current_image.window) == current_image.buffer
              if not is_buffer_in_window then current_image:clear() end
            end
          end
        end
      end)
    end,
  })

  -- rerender on scroll
  vim.api.nvim_create_autocmd({ "WinScrolled" }, {
    group = group,
    callback = function(au)
      local images = api.get_images({ window = tonumber(au.file) })
      for _, current_image in ipairs(images) do
        current_image:render()
      end
    end,
  })

  -- force rerender on resize (handles VimResized as well)
  vim.api.nvim_create_autocmd({ "WinResized", "WinNew" }, {
    group = group,
    callback = function()
      local images = api.get_images()
      for _, current_image in ipairs(images) do
        if current_image.window ~= nil then
          current_image:clear()
          current_image:render()
        end
      end
    end,
  })

  -- auto-clear on VimSuspend and re-render on VimResume
  local image_to_restore_on_resume = {}
  vim.api.nvim_create_autocmd({ "VimSuspend" }, {
    group = group,
    callback = function()
      local images = api.get_images()
      for _, current_image in ipairs(images) do
        current_image:clear()
      end
      image_to_restore_on_resume = images
    end,
  })
  vim.api.nvim_create_autocmd({ "VimResume" }, {
    group = group,
    callback = function()
      local images = image_to_restore_on_resume
      for _, current_image in ipairs(images) do
        current_image:render()
      end
    end,
  })

  -- auto-toggle on editor focus change
  if
    state.options.editor_only_render_when_focused
    or (state.options.tmux_show_only_in_active_window and utils.tmux.is_tmux)
  then
    local images_to_restore_on_focus = {}
    local initial_tmux_window_id = utils.tmux.get_window_id()
    local initial_tmux_session = utils.tmux.get_current_session()

    vim.api.nvim_create_autocmd("FocusLost", {
      group = group,
      callback = function() -- auto-clear images when windows and buffers change
        vim.schedule(function()
          -- utils.debug("FocusLost")

          if
            state.options.editor_only_render_when_focused
            or (utils.tmux.is_tmux and utils.tmux.get_window_id() ~= initial_tmux_window_id)
            or (utils.tmux.is_tmux and utils.tmux.get_current_session() ~= initial_tmux_session)
          then
            state.disable_decorator_handling = true

            local images = api.get_images()
            for _, current_image in ipairs(images) do
              if current_image.is_rendered then
                current_image:clear(true)
                table.insert(images_to_restore_on_focus, current_image)
              end
            end
          end
        end)
      end,
    })

    vim.api.nvim_create_autocmd("FocusGained", {
      group = group,
      callback = function() -- auto-clear images when windows and buffers change
        -- utils.debug("FocusGained")

        state.disable_decorator_handling = false

        vim.schedule_wrap(function()
          -- force rerender
          local images = api.get_images()
          for _, current_image in ipairs(images) do
            if current_image.is_rendered then
              current_image:clear()
              current_image:render()
            end
          end

          -- render images cleared on focus loss
          for _, current_image in ipairs(images_to_restore_on_focus) do
            current_image:render()
          end
          images_to_restore_on_focus = {}
        end)()
      end,
    })
  end

  -- hijack image filetypes
  if state.options.hijack_file_patterns and #state.options.hijack_file_patterns > 0 then
    vim.api.nvim_create_autocmd({
      "WinNew",
      "BufWinEnter",
      "TabEnter",
    }, {
      group = group,
      pattern = state.options.hijack_file_patterns,
      callback = function(event)
        local buf = event.buf
        local win = vim.api.nvim_get_current_win()
        local path = vim.api.nvim_buf_get_name(buf)

        api.hijack_buffer(path, win, buf)
      end,
    })
  end

  -- sync with extmarks
  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI", "InsertEnter" }, {
    group = group,
    callback = function(event)
      local images = api.get_images({ buffer = event.buf })
      for _, img in ipairs(images) do
        local has_moved, extmark_y, extmark_x = img:has_extmark_moved()
        if has_moved and extmark_x and extmark_y then
          img.geometry.y = extmark_y
          img.geometry.x = extmark_x
          img.extmark.col = extmark_x
          img.extmark.row = extmark_y
          img:render()
        end
      end
    end,
  })

  -- add :ImageReport
  vim.api.nvim_create_user_command("ImageReport", function()
    api.create_report()
  end, {})
end

local guard_setup = function()
  if not state.backend then utils.throw("image.nvim is not setup. Call setup() first.") end
end

---@param path string
---@param win number? if nil or 0, uses current window
---@param buf number? if nil or 0, uses current buffer
---@param options ImageOptions?
---@return Image|nil
api.hijack_buffer = function(path, win, buf, options)
  if not win or win == 0 then win = vim.api.nvim_get_current_win() end
  if not buf or buf == 0 then buf = vim.api.nvim_get_current_buf() end

  local key = ("%s:%s"):format(win, buf)
  if state.hijacked_win_buf_images[key] then
    state.hijacked_win_buf_images[key]:render()
    return state.hijacked_win_buf_images[key]
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "" })

  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nowrite"
  vim.bo[buf].filetype = "image_nvim"
  vim.opt_local.colorcolumn = "0"
  vim.opt_local.cursorline = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "no"

  local opts = options or {}
  opts.window = win
  opts.buffer = buf

  local img = api.from_file(path, opts)

  if img then
    img:render()
    state.hijacked_win_buf_images[key] = img
  end

  return img
end

---@param path string
---@param options? ImageOptions
api.from_file = function(path, options)
  guard_setup()
  local image = require("image/image")
  return image.from_file(path, options, state)
end

---@param url string
---@param options? ImageOptions
---@param callback fun(image: Image|nil)
api.from_url = function(url, options, callback)
  guard_setup()
  local image = require("image/image")
  image.from_url(url, options, callback, state)
end

---@param id? string
api.clear = function(id)
  guard_setup()
  local target = state.images[id]
  if target then
    target:clear()
  else
    state.backend.clear(id)
  end
end

---@param opts? { window?: number, buffer?: number, namespace?: string }
---@return Image[]
api.get_images = function(opts)
  local images = {}
  local namespace = opts and opts.namespace or nil
  for _, current_image in pairs(state.images) do
    if (namespace and current_image.namespace == namespace) or not namespace then
      if
        (opts and opts.window and opts.window == current_image.window and not opts.buffer)
        or (opts and opts.buffer and opts.buffer == current_image.buffer and not opts.window)
        or (opts and opts.window and opts.buffer and opts.window == current_image.window and opts.buffer == current_image.buffer)
        or not opts
      then
        table.insert(images, current_image)
      end
    end
  end
  return images
end

api.create_report = function()
  guard_setup()
  return report.create(state)
end

return api
