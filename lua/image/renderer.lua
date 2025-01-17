local utils = require("image/utils")

-- Images get resized and cropped to fit in the context they are rendered in.
-- Each of these versions are written to the temp directory and cleared on reboot (on Linux at least).
-- This is where we keep track of the hashes of the resized and cropped versions of the images so we
-- can avoid processing and writing the same cropped/resized image variant multiple times.
---@type table<string, { resized: table<string>, cropped: table<string> }>
local cache = {}

-- FIXME: having multiple instances of the same image that are bounded to
--  different sizes cause the virt_line calculations to break (i think the 
--  height gets miss calculated)

-- FIXME: horrible performance when you resize a window so that the image 
--  "bounding box" changes

-- (both of those existed before i refactored / rewrote the renderer)

---@param image Image
local render = function(image)
  local state = image.global_state
  local term_size = utils.term.get_size()
  local scale_factor = 1.0
  if type(state.options.scale_factor) == "number" then scale_factor = state.options.scale_factor end
  local image_rows = math.floor(image.image_height / term_size.cell_height * scale_factor)
  local image_columns = math.floor(image.image_width / term_size.cell_width * scale_factor)
  local image_cache = cache[image.original_path] or { resized = {}, cropped = {} }

  -- utils.debug(("renderer.render() %s"):format(image.id), {
  --   id = image.id,
  --   x = image.geometry.x,
  --   y = image.geometry.y,
  --   width = image.geometry.width,
  --   height = image.geometry.height,
  -- })

  local original_x = image.geometry.x or 0
  local original_y = image.geometry.y or 0
  local width = image.geometry.width or 0
  local height = image.geometry.height or 0
  local bounds = {
    top = 0,
    right = term_size.screen_cols,
    bottom = term_size.screen_rows,
    left = 0,
  }

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
  -- width = math.min(width, image_columns)
  -- height = math.min(height, image_rows)

  -- screen max width/height
  width = math.min(width, term_size.screen_cols)
  -- height = math.min(height, term_size.screen_rows)

  -- utils.debug(
  --   ("(1) x: %d, y: %d, width: %d, height: %d y_offset: %d"):format(original_x, original_y, width, height, y_offset)
  -- )

  if image.window ~= nil then
    -- utils.debug(vim.fn.getwininfo(image.window)[1])

    -- bail if the window is invalid
    local window = utils.window.get_window(image.window, {
      with_masks = state.options.window_overlap_clear_enabled,
      ignore_masking_filetypes = state.options.window_overlap_clear_ft_ignore,
    })
    if window == nil then
      -- utils.debug("invalid window", image.id)
      return false
    end

    -- bail if the window is not visible
    if not window.is_visible then
      -- utils.debug("windows not visible", image.id)
      return false
    end

    -- bail if the window is overlapped
    if state.options.window_overlap_clear_enabled and #window.masks > 0 then
      -- utils.debug("overlap", image.id)
      return false
    end

    -- if the image is tied to a buffer the window must be displaying that buffer
    if image.buffer ~= nil and window.buffer ~= image.buffer then
      -- utils.debug("bufffer not shown", image.id)
      return false
    end

    -- check if image is in fold
    local current_win = vim.api.nvim_get_current_win()
    vim.api.nvim_command("noautocmd call nvim_set_current_win(" .. image.window .. ")")
    local is_folded = vim.fn.foldclosed(original_y) ~= -1
    vim.api.nvim_command("noautocmd call nvim_set_current_win(" .. current_win .. ")")

    -- bail if it is
    if image.buffer and is_folded then
      -- utils.debug("image is inside a fold", image.id)
      state.images[image.id] = image
      image:clear(true)
      return false
    end

    -- global offsets
    local global_offsets = utils.offsets.get_global_offsets(window.id)
    -- window bounds
    bounds = window.rect
    bounds.bottom = bounds.bottom - 1

    -- this is ugly, and if get_global_offsets() is changed this could break
    bounds.top = bounds.top + global_offsets.y
    bounds.bottom = bounds.bottom + global_offsets.y
    bounds.left = bounds.left + global_offsets.x
    bounds.right = bounds.right

    if utils.offsets.get_border_shape(window.id).left > 0 then
      bounds.right = bounds.right + 1 --
    end

    local max_width_window_percentage = --
      image.max_width_window_percentage --
      or state.options.max_width_window_percentage

    local max_height_window_percentage = --
      image.max_height_window_percentage --
      or state.options.max_height_window_percentage

    if type(max_width_window_percentage) == "number" then
      width = math.min(
        -- original
        width,
        -- max_window_percentage
        math.floor((window.width - global_offsets.x) * max_width_window_percentage / 100)
      )
    end
    if type(max_height_window_percentage) == "number" then
      height = math.min(
        -- original
        height,
        -- max_window_percentage
        math.floor((window.height - global_offsets.y) * max_height_window_percentage / 100)
      )
    end
  end

  -- utils.debug(
  --   ("(2) x: %d, y: %d, width: %d, height: %d y_offset: %d"):format(original_x, original_y, width, height, y_offset)
  -- )

  -- global max width/height
  if type(state.options.max_width) == "number" then width = math.min(width, state.options.max_width) end
  if type(state.options.max_height) == "number" then height = math.min(height, state.options.max_height) end

  width, height = utils.math.adjust_to_aspect_ratio(term_size, image.image_width, image.image_height, width, height)
  
  local absolute_x, absolute_y
  if image.window == nil then
    absolute_x = original_x
    absolute_y = original_y
  else
    local win_info = vim.fn.getwininfo(image.window)[1]
    --
    local screen_pos = vim.fn.screenpos(
      image.window,
      -- put it bellow the "image source"
      original_y + 1,
      original_x
    )


    if
      screen_pos.col == 0 --
      and screen_pos.row == 0 --
    then
      -- the screen_pos is outside the window

      -- Calculate the difference between the top line and top pos of window
      -- Its the best way i found to calculate the possible extmark virt_lines
      -- that could be partially scrolled away.
      local diff = vim.fn.screenpos(image.window, win_info.topline, 0).row - win_info.winrow

      if diff <= 0 then
        return false -- out of bounds
      end

      -- there is a diff which means that there are virt_lines that the user has
      -- partially scrolled past

      absolute_y = win_info.winrow - height + diff - 1 -- fking 1 indexing
      -- Try to manually calculate the x pos of the image.
      -- We cant use the "built in" one since its out of bounds of the window
      -- and therefore returns two 0s
      -- Maybe do that all the time so that wrapping doesn't affect the x pos of
      -- the image.
      absolute_x = win_info.wincol + win_info.textoff + original_x - 1 -- fking 1 indexing
    else
      absolute_x = screen_pos.col
      absolute_y = screen_pos.row
    end
  end

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
    -- utils.debug("out of bounds")
    return false
  end

  -- compute final geometry and prevent useless re rendering
  local rendered_geometry = { x = absolute_x, y = absolute_y, width = width, height = height }
  -- utils.debug("rendered_geometry", rendered_geometry, vim.fn.getwininfo(image.window)[1])

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
  if image.image_width ~= pixel_width then needs_resize = true end

  -- TODO make this non-blocking

  -- resize
  if needs_resize then
    if image.resize_hash ~= resize_hash then
      local cached_path = image_cache.resized[resize_hash]

      -- try cache
      if cached_path then
        -- utils.debug(("using cached resized image %s"):format(cached_path))
        image.resized_path = cached_path
        image.resize_hash = resize_hash
      else
        -- perform resize
        local tmp_path = state.tmp_dir .. "/" .. vim.base64.encode(image.id) .. "-resized-" .. resize_hash .. ".png"
        image.resized_path = state.processor.resize(image.path, pixel_width, pixel_height, tmp_path)
        image.resize_hash = resize_hash
        image_cache.resized[resize_hash] = image.resized_path
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
      local cached_path = image_cache.cropped[crop_hash]

      -- try cache;
      if cached_path then
        -- utils.debug(("using cached cropped image %s"):format(cached_path))
        image.cropped_path = cached_path
        image.crop_hash = crop_hash
      else
        -- perform crop
        local tmp_path = state.tmp_dir .. "/" .. vim.base64.encode(image.id) .. "-cropped-" .. crop_hash .. ".png"
        image.cropped_path = state.processor.crop(
          image.resized_path or image.path,
          0,
          crop_offset_top,
          pixel_width,
          cropped_pixel_height,
          tmp_path
        )
        image.crop_hash = crop_hash
        image_cache.cropped[crop_hash] = image.cropped_path
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
  cache[image.original_path] = image_cache

  -- utils.debug("rendered")
  return true
end

local clear_cache_for_path = function(path)
  cache[path] = nil
end

return {
  render = render,
  clear_cache_for_path = clear_cache_for_path,
}
