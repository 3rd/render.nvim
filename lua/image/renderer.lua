local magick = require("image/magick")
local utils = require("image/utils")

-- Images get resized and cropped to fit in the context they are rendered in.
-- Each of these versions are written to the temp directory and cleared on reboot (on Linux at least).
-- This is where we keep track of the hashes of the resized and cropped versions of the images so we
-- can avoid processing and writing the same cropped/resized image variant multiple times.
local cache = {
  resized = {}, -- { [`${original_path}:${resize_hash}`]: string }
  cropped = {}, -- { [`${original_path}:${crop_hash}`]: string }
}

---@param image Image
local render = function(image)
  local state = image.global_state
  local term_size = utils.term.get_size()
  local image_rows = math.floor(image.image_height / term_size.cell_height)
  local image_columns = math.floor(image.image_width / term_size.cell_width)

  -- utils.debug(("renderer.render() %s"):format(image.id), {
  --   id = image.id,
  --   x = image.geometry.x,
  --   y = image.geometry.y,
  --   width = image.geometry.width,
  --   height = image.geometry.height,
  -- })

  local original_x = image.geometry.x or 0
  local original_y = image.geometry.y or 0
  local x_offset = 0
  local y_offset = 0
  local width = image.geometry.width or 0
  local height = image.geometry.height or 0
  local window_offset_x = 0
  local window_offset_y = 0
  local bounds = {
    top = 0,
    right = term_size.screen_cols,
    bottom = term_size.screen_rows,
    left = 0,
  }
  local topfill = 0

  -- infer missing w/h component
  local aspect_ratio = image.image_width / image.image_height
  local geometry_width_px = width * term_size.cell_width
  local geometry_height_px = height * term_size.cell_height
  if width == 0 and height ~= 0 then width = math.ceil(geometry_height_px * aspect_ratio / term_size.cell_width) end
  if height == 0 and width ~= 0 then height = math.ceil(geometry_width_px / aspect_ratio / term_size.cell_height) end

  -- if both w/h are missing, use the image dimensions
  if width == 0 and height == 0 then
    width = image_columns
    height = image_rows
  end

  -- rendered size cannot be larger than the image itself
  width = math.min(width, image_columns)
  height = math.min(height, image_rows)

  -- screen max width/height
  width = math.min(width, term_size.screen_cols)
  height = math.min(height, term_size.screen_rows)

  -- utils.debug(("(1) x: %d, y: %d, width: %d, height: %d y_offset: %d"):format(original_x, original_y, width, height, y_offset))

  if image.window ~= nil then
    -- bail if the window is invalid
    local window = utils.window.get_window(image.window, {
      with_masks = state.options.window_overlap_clear_enabled,
      ignore_masking_filetypes = state.options.window_overlap_clear_ft_ignore,
    })
    if window == nil then
      utils.debug("invalid window", image.id)
      return false
    end

    -- bail if the window is not visible
    if not window.is_visible then return false end

    -- bail if the window is overlapped
    if state.options.window_overlap_clear_enabled and #window.masks > 0 then return false end

    -- if the image is tied to a buffer the window must be displaying that buffer
    if image.buffer ~= nil and window.buffer ~= image.buffer then return false end

    -- get topfill and check fold status
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_command("noautocmd call nvim_set_current_win(" .. image.window .. ")")
    topfill = vim.fn.winsaveview().topfill
    local is_folded = vim.fn.foldclosed(original_y) ~= -1
    vim.api.nvim_command("noautocmd call nvim_set_current_win(" .. current_win .. ")")

    -- bail if the image is inside a fold
    if image.buffer and is_folded then
      -- utils.debug("image is inside a fold", image.id)
      state.images[image.id] = image
      image:clear(true)
      return false
    end

    -- global offsets
    local global_offsets = utils.offsets.get_global_offsets(window.id)
    x_offset = global_offsets.x - window.scroll_x
    y_offset = global_offsets.y - window.scroll_y

    -- window offsets
    window_offset_x = window.x
    window_offset_y = window.y

    -- window bounds
    bounds = window.rect
    bounds.bottom = bounds.bottom - 1

    -- this is ugly, and if get_global_offsets() is changed this could break
    bounds.top = bounds.top + global_offsets.y
    bounds.bottom = bounds.bottom + global_offsets.y
    bounds.left = bounds.left + global_offsets.x
    bounds.right = bounds.right
    if utils.offsets.get_border_shape(window.id).left > 0 then bounds.right = bounds.right + 1 end

    -- global max window width/height percentage
    if not image.ignore_global_max_size then
      if type(state.options.max_width_window_percentage) == "number" then
        width = math.min(
          width,
          math.floor((window.width - global_offsets.x) * state.options.max_width_window_percentage / 100)
        )
      end
      if type(state.options.max_height_window_percentage) == "number" then
        height = math.min(
          height,
          math.floor((window.height - global_offsets.y) * state.options.max_height_window_percentage / 100)
        )
      end
    end
  end

  -- utils.debug(
  --   ("(2) x: %d, y: %d, width: %d, height: %d y_offset: %d"):format(original_x, original_y, width, height, y_offset)
  -- )

  -- global max width/height
  if not image.ignore_global_max_size then
    if type(state.options.max_width) == "number" then width = math.min(width, state.options.max_width) end
    if type(state.options.max_height) == "number" then height = math.min(height, state.options.max_height) end
  end

  width, height = utils.math.adjust_to_aspect_ratio(term_size, image.image_width, image.image_height, width, height)

  if width <= 0 or height <= 0 then return false end

  -- utils.debug(("(3) x: %d, y: %d, width: %d, height: %d y_offset: %d"):format(original_x, original_y, width, height, y_offset))

  local absolute_x = original_x + x_offset + window_offset_x
  local absolute_y = original_y + y_offset + window_offset_y

  if image.with_virtual_padding then absolute_y = absolute_y + 1 end

  local prevent_rendering = false

  -- utils.debug(("(4) x: %d, y: %d, width: %d, height: %d y_offset: %d absolute_x: %d absolute_y: %d"):format( original_x, original_y, width, height, y_offset, absolute_x, absolute_y))

  if image.window and image.buffer then
    local win_info = vim.fn.getwininfo(image.window)[1]
    if not win_info then return false end
    local topline = win_info.topline
    local botline = win_info.botline

    -- bail if out of bounds
    if original_y + 1 < topline or original_y > botline then
      -- utils.debug("prevent rendering 1", image.id)
      prevent_rendering = true
    end

    -- folds
    local offset = 0
    local current_win = vim.api.nvim_get_current_win()
    -- TODO: can this be done without switching windows?
    vim.api.nvim_command("noautocmd call nvim_set_current_win(" .. image.window .. ")")

    local folded_ranges = {}
    if vim.wo.foldenable then
      local i = topline
      while i <= original_y do
        local fold_start, fold_end = vim.fn.foldclosed(i), vim.fn.foldclosedend(i)
        if fold_start ~= -1 and fold_end ~= -1 then
          -- utils.debug(("i: %d fold start: %d, fold end: %d"):format(i, fold_start, fold_end))
          folded_ranges[fold_start] = fold_end
          offset = offset + (fold_end - fold_start)
          i = fold_end + 1
        else
          i = i + 1
        end
      end
    end
    vim.api.nvim_command("noautocmd call nvim_set_current_win(" .. current_win .. ")")
    -- utils.debug(("fold offset: %d"):format(offset))
    absolute_y = absolute_y - offset

    -- account for things that push line numbers around
    if image.inline then
      -- bail if the image is above the top of the window at least by one line
      if topfill == 0 and original_y < topline then
        -- utils.debug("prevent rendering 2", image.id)
        prevent_rendering = true
      end

      -- bail if the image + its height is above the top of the window + topfill
      -- if y + height + 1 < topline + topfill then
      --   utils.debug("prevent rendering 3", image.id, {
      --     y = y,
      --     height = height,
      --     topline = topline,
      --     topfill = topfill,
      --   })
      --   prevent_rendering = true
      -- end

      -- bail if the image is below the bottom of the window
      if original_y > botline then
        -- utils.debug("prevent rendering 4", image.id)
        prevent_rendering = true
      end

      -- offset by topfill if the image started above the top of the window
      if not prevent_rendering then
        if topfill > 0 and original_y < topline then
          --
          absolute_y = absolute_y - (height - topfill)
        else
          -- offset by any pre-y virtual lines
          local extmarks = vim.tbl_map(
            function(mark)
              ---@diagnostic disable-next-line: deprecated
              local mark_id, mark_row, mark_col, mark_opts = unpack(mark)
              local virt_height = #(mark_opts.virt_lines or {})
              return { id = mark_id, row = mark_row, col = mark_col, height = virt_height }
            end,
            vim.api.nvim_buf_get_extmarks(
              image.buffer,
              -1,
              { topline - 1, 0 },
              { original_y - 1, 0 },
              { details = true }
            )
          )

          local extmark_y_offset = topfill
          for _, mark in ipairs(extmarks) do
            if image.extmark and image.extmark.id == mark.id then goto continue end
            if mark.row ~= original_y and mark.id ~= image:get_extmark_id() then
              -- check the mark is inside a fold, and skip adding the offset if it is
              for fold_start, fold_end in pairs(folded_ranges) do
                if mark.row >= fold_start and mark.row < fold_end then goto continue end
              end
              extmark_y_offset = extmark_y_offset + mark.height
            end
            ::continue::
          end

          -- offset x by inline virtual text
          local extmark_x_offset = 0
          -- track positions that are concealed by extmarks
          local extmark_concealed = {}
          local same_line_extmarks = vim.api.nvim_buf_get_extmarks(
            image.buffer,
            -1,
            { original_y, 0 },
            { original_y, original_x - 2 },
            { details = true }
          )
          for _, extmark in ipairs(same_line_extmarks) do
            if extmark[3] >= original_x then goto continue end
            local details = extmark[4]
            if details.virt_text_pos == "inline" then
              -- add the width b/c this takes up space
              extmark_x_offset = extmark_x_offset + utils.offsets.virt_text_width(details.virt_text)
            end

            local conceallevel = vim.wo[image.window].conceallevel
            -- TODO: account for conceal cursor?
            local conceal_current_line = vim.api.nvim_win_get_cursor(image.window)[1] ~= original_x
              and conceallevel > 0
            if details.conceal and details.end_col and conceal_current_line then
              -- remove width b/c this is removing space
              for i = extmark[3], details.end_col do
                extmark_concealed[i] = true
              end
              extmark_x_offset = extmark_x_offset - (details.end_col - extmark[3])

              if conceallevel ~= 3 then
                -- concealed text will be replaced with a single character
                extmark_x_offset = extmark_x_offset + math.min(string.len(details.conceal), 1)
              end
            end
            ::continue::
          end

          local sum = 0
          for i = 0, original_x - 1 do
            local res = vim.inspect_pos(
              image.buffer,
              original_y,
              i,
              { semantic_tokens = false, syntax = false, extmarks = false, treesitter = true }
            )
            for _, hl in ipairs(res.treesitter) do
              if hl.capture == "conceal" and not extmark_concealed[i + 1] then
                sum = sum + 1
                break
              end
            end
          end
          extmark_x_offset = extmark_x_offset - sum

          absolute_y = absolute_y + extmark_y_offset
          absolute_x = absolute_x + extmark_x_offset
        end
      end
    end
  end

  if prevent_rendering then absolute_y = -math.huge end

  -- clear out of bounds images
  if
    absolute_y + height <= bounds.top
    or absolute_y >= bounds.bottom + (vim.o.laststatus == 2 and 1 or 0)
    or absolute_x + width <= bounds.left
    or absolute_x >= bounds.right
  then
    if image.is_rendered then
      -- utils.debug("deleting out of bounds image", { id = image.id, x = absolute_x, y = absolute_y, width = width, height = height, bounds = bounds })
      state.backend.clear(image.id, true)
    else
      state.images[image.id] = image
    end
    return false
  end

  -- compute final geometry and prevent useless rerendering
  local rendered_geometry = { x = absolute_x, y = absolute_y, width = width, height = height }
  -- utils.debug("rendered_geometry", rendered_geometry)

  -- handle crop/resize
  local pixel_width = width * term_size.cell_width
  local pixel_height = height * term_size.cell_height
  local crop_offset_top = 0
  local cropped_pixel_height = height * term_size.cell_height
  local needs_crop = false
  local needs_resize = false
  local initial_crop_hash = image.crop_hash
  local initial_resize_hash = image.resize_hash

  -- compute crop top/bottom
  -- crop top
  if absolute_y < bounds.top then
    local visible_rows = height - (bounds.top - absolute_y)
    cropped_pixel_height = visible_rows * term_size.cell_height
    crop_offset_top = (bounds.top - absolute_y) * term_size.cell_height
    if not state.backend.features.crop then absolute_y = bounds.top end
    needs_crop = true
  end

  -- crop bottom
  if absolute_y + height > bounds.bottom then
    cropped_pixel_height = (bounds.bottom - absolute_y + 1) * term_size.cell_height
    needs_crop = true
  end

  -- compute resize
  local resize_hash = ("%d-%d"):format(pixel_width, pixel_height)
  if image.image_width > pixel_width then needs_resize = true end

  -- TODO make this non-blocking

  -- resize
  if needs_resize then
    if image.resize_hash ~= resize_hash then
      local cached_path = cache.resized[image.path .. ":" .. resize_hash]

      -- try cache
      if cached_path then
        -- utils.debug(("using cached resized image %s"):format(cached_path))
        image.resized_path = cached_path
        image.resize_hash = resize_hash
      else
        -- perform resize
        local resized_image = magick.load_image(image.path)
        if resized_image then
          -- utils.debug(("resizing image %s to %dx%d"):format(image.path, pixel_width, pixel_height))
          --
          resized_image:set_format("png")
          resized_image:scale(pixel_width, pixel_height)

          local tmp_path = state.tmp_dir
            .. "/"
            .. utils.base64.encode(image.id)
            .. "-resized-"
            .. resize_hash
            .. ".png"
          resized_image:write(tmp_path)
          resized_image:destroy()

          image.resized_path = tmp_path
          image.resize_hash = resize_hash

          cache.resized[image.path .. ":" .. resize_hash] = tmp_path
        end
      end
    end
  else
    image.resized_path = image.path
    image.resize_hash = nil
  end

  -- crop
  local crop_hash = ("%d-%d-%d-%d"):format(0, crop_offset_top, pixel_width, cropped_pixel_height)
  if needs_crop and not state.backend.features.crop then
    if (needs_resize and image.resize_hash ~= resize_hash) or image.crop_hash ~= crop_hash then
      local cached_path = cache.cropped[image.path .. ":" .. crop_hash]

      -- try cache;
      if cached_path then
        -- utils.debug(("using cached cropped image %s"):format(cached_path))
        image.cropped_path = cached_path
        image.crop_hash = crop_hash
      else
        -- perform crop
        -- utils.debug(("cropping image %s to %dx%d"):format(image.path, pixel_width, cropped_pixel_height))

        local cropped_image = magick.load_image(image.resized_path or image.path)
        cropped_image:set_format("png")
        cropped_image:crop(pixel_width, cropped_pixel_height, 0, crop_offset_top)

        local tmp_path = state.tmp_dir .. "/" .. utils.base64.encode(image.id) .. "-cropped-" .. crop_hash .. ".png"
        cropped_image:write(tmp_path)
        cropped_image:destroy()

        image.cropped_path = tmp_path

        image.crop_hash = crop_hash

        cache.cropped[image.path .. ":" .. crop_hash] = image.cropped_path
      end
    end
  elseif needs_crop then
    image.cropped_path = image.resized_path
    image.crop_hash = crop_hash
  else
    image.cropped_path = image.resized_path
    image.crop_hash = nil
  end

  if
    image.is_rendered
    and image.rendered_geometry.x == rendered_geometry.x
    and image.rendered_geometry.y == rendered_geometry.y
    and image.rendered_geometry.width == rendered_geometry.width
    and image.rendered_geometry.height == rendered_geometry.height
    and image.crop_hash == initial_crop_hash
    and image.resize_hash == initial_resize_hash
  then
    -- utils.debug("skipping render", image.id)
    return true
  end

  -- utils.debug("redering to backend", image.id, { x = absolute_x, y = absolute_y, width = width, height = height, resize_hash = image.resize_hash, crop_hash = image.crop_hash, })

  image.bounds = bounds
  state.backend.render(image, absolute_x, absolute_y, width, height)
  image.rendered_geometry = rendered_geometry
  -- utils.debug("rendered", image)

  return true
end

return {
  render = render,
}
