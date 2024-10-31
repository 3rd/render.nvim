local magick = require("image/magick")
local renderer = require("image/renderer")
local utils = require("image/utils")

-- { ["buf:row:col"]: { id, height } }
---@type table<string, { id: number, height: number }>
local buf_extmark_map = {}

---@class Image
local Image = {
  next_internal_id = 1,
}
Image.__index = Image

---@param template Image
---@param global_state State
---@return Image
local createImage = function(template, global_state)
  local instance = template or { geometry = { x = 0, y = 0 } }
  instance.global_state = global_state

  instance.internal_id = Image.next_internal_id
  Image.next_internal_id = Image.next_internal_id + 1

  setmetatable(instance, Image)
  return instance
end

---get the extmark id for the virtual padding for this image
---@return number?
function Image:get_extmark_id()
  local extmark = buf_extmark_map[self.buffer .. ":" .. self.geometry.y .. ":" .. self.geometry.x]
  if extmark then return extmark.id end
end

function Image:has_extmark_moved()
  if not self.extmark then return false end
  local extmark =
    vim.api.nvim_buf_get_extmark_by_id(self.buffer, self.global_state.extmarks_namespace, self.extmark.id, {})
  if extmark then
    local moved = extmark[1] ~= self.extmark.row or extmark[2] ~= self.extmark.col
    return moved, extmark[1], extmark[2]
  end
  return false
end

---@param geometry? ImageGeometry
function Image:render(geometry)
  if not self.global_state.enabled then return end

  if geometry then self.geometry = vim.tbl_deep_extend("force", self.geometry, geometry) end

  -- don't render if we are in the conmmand-line-window, in this case previously rendered images can
  -- be left in place
  if vim.fn.getcmdwintype() ~= "" then return end

  -- track last_modified and wipe cache
  local current_last_modified = vim.fn.getftime(self.original_path)
  -- utils.debug(("timestamp: %s, last_modified: %s"):format(current_last_modified, self.last_modified))
  if self.last_modified ~= current_last_modified then
    self.last_modified = current_last_modified
    self.resize_hash = nil
    self.cropped_hash = nil
    self.resize_hash = nil

    local magick_image = magick.load_image(self.original_path)

    if magick_image:get_format():lower() ~= "png" then
      local converted_path = self.global_state.tmp_dir .. "/" .. utils.base64.encode(self.id) .. "-source.png"
      magick_image:set_format("png")
      magick_image:write(converted_path)
      self.path = converted_path
    end

    self:clear()
    self.image_width = magick_image:get_width()
    self.image_height = magick_image:get_height()

    magick_image:destroy()

    renderer.clear_cache_for_path(self.original_path)
  end

  -- utils.debug(("---------------- %s ----------------"):format(self.id))
  local was_rendered = renderer.render(self)

  -- utils.debug(
  --   ("[image] render: %s, success: %s x: %s, y: %s, width: %s, height: %s"):format(
  --     self.id,
  --     was_rendered,
  --     self.geometry.x,
  --     self.geometry.y,
  --     self.geometry.width,
  --     self.geometry.height
  --   )
  -- )

  -- clear if already rendered but rendering this should be prevented
  if self.is_rendered and not was_rendered then
    self.global_state.backend.clear(self.id, true)
    return
  end

  -- virtual padding
  if was_rendered and self.buffer and self.inline then
    local row = self.geometry.y
    local col = self.geometry.x
    local height = self.rendered_geometry.height

    local extmark_key = self.buffer .. ":" .. row .. ":" .. col
    local previous_extmark = buf_extmark_map[extmark_key]

    -- create extmark
    if was_rendered then
      local has_up_to_date_extmark = previous_extmark and previous_extmark.height == height

      if not has_up_to_date_extmark then
        if previous_extmark ~= nil then
          -- utils.debug(("(image.render) clearing extmark %s"):format(previous_extmark.id))
          vim.api.nvim_buf_del_extmark(self.buffer, self.global_state.extmarks_namespace, previous_extmark.id)
          buf_extmark_map[extmark_key] = nil
        end

        local filler = {}
        local extmark_opts = { id = self.internal_id, strict = false }
        if self.with_virtual_padding then
          for _ = 0, height - 1 do
            filler[#filler + 1] = { { " ", "" } }
          end
          extmark_opts.virt_lines = filler
        end

        -- utils.debug(("(image.render) creating extmark %s"):format(self.internal_id))
        local extmark_row = math.max(row or 0, 0)
        local extmark_col = math.max(col or 0, 0)
        local ok, extmark_id = pcall(
          vim.api.nvim_buf_set_extmark,
          self.buffer,
          self.global_state.extmarks_namespace,
          extmark_row,
          extmark_col,
          extmark_opts
        )
        if ok then
          buf_extmark_map[extmark_key] = { id = self.internal_id, height = height or 0 }
          self.extmark = { id = extmark_id, row = extmark_row, col = extmark_col }
        end
      end
    end

    if self.with_virtual_padding then
      -- rerender any images that are below this one
      local to_be_rerendered = vim.tbl_filter(function(x)
        return x.is_rendered and x.buffer == self.buffer and x.geometry.y > self.geometry.y
      end, vim.tbl_values(self.global_state.images))
      table.sort(to_be_rerendered, function(a, b)
        return a.geometry.y < b.geometry.y
      end)
      for _, image in ipairs(to_be_rerendered) do
        image:render()

        if image.with_virtual_padding then break end
      end
    end
  end
end

---@param shallow? boolean
function Image:clear(shallow)
  -- utils.debug(("[image] clear %s, shallow: %s"):format(self.id, shallow))
  self.global_state.backend.clear(self.id, shallow or false)

  self.rendered_geometry = {
    x = nil,
    y = nil,
    width = nil,
    height = nil,
  }

  -- All virtual padding images will have inline == true. And an image only gets one extmark, so
  -- this will correctly cleanup all extmarks
  if self.inline and self.buffer then
    if vim.api.nvim_buf_is_valid(self.buffer) then
      vim.api.nvim_buf_del_extmark(self.buffer, self.global_state.extmarks_namespace, self.internal_id)
    end
    buf_extmark_map[self.buffer .. ":" .. self.geometry.y .. ":" .. self.geometry.x] = nil
  end
end

function Image:move(x, y)
  self.geometry.x = x
  self.geometry.y = y
  self:render()
end

---@param brightness number
function Image:brightness(brightness)
  local magick_image = magick.load_image(self.path)
  if not magick_image then error(("image.nvim: magick failed to load image: %s"):format(self.path)) end
  magick_image:modulate(brightness)
  local altered_path = self.global_state.tmp_dir .. "/" .. utils.base64.encode(self.id) .. "-source.png"
  magick_image:write(altered_path)
  magick_image:destroy()

  self.path = altered_path
  self.cropped_path = altered_path
  self.resize_hash = nil
  self.cropped_hash = nil
  self.resize_hash = nil
  if self.is_rendered then
    self:clear()
    self:render()
  end
end

---@param saturation number
function Image:saturation(saturation)
  local magick_image = magick.load_image(self.path)
  if not magick_image then error(("image.nvim: magick failed to load image: %s"):format(self.path)) end
  magick_image:modulate(nil, saturation)
  local altered_path = self.global_state.tmp_dir .. "/" .. utils.base64.encode(self.id) .. "-source.png"
  magick_image:write(altered_path)
  magick_image:destroy()

  self.path = altered_path
  self.cropped_path = altered_path
  self.resize_hash = nil
  self.cropped_hash = nil
  self.resize_hash = nil
  if self.is_rendered then
    self:clear()
    self:render()
  end
end

---@param hue number
function Image:hue(hue)
  local magick_image = magick.load_image(self.path)
  if not magick_image then error(("image.nvim: magick failed to load image: %s"):format(self.path)) end
  magick_image:modulate(nil, nil, hue)
  local altered_path = self.global_state.tmp_dir .. "/" .. utils.base64.encode(self.id) .. "-source.png"
  magick_image:write(altered_path)
  magick_image:destroy()

  self.path = altered_path
  self.cropped_path = altered_path
  self.resize_hash = nil
  self.cropped_hash = nil
  self.resize_hash = nil
  if self.is_rendered then
    self:clear()
    self:render()
  end
end

---@param path string
---@param options? ImageOptions
---@param state State
---@return Image|nil
local from_file = function(path, options, state)
  local opts = options or {}

  if options and options.id then
    local existing_image = state.images[options.id] ---@type Image
    if existing_image then return existing_image end
  end

  local absolute_original_path = vim.fn.fnamemodify(path, ":p")
  if not vim.loop.fs_stat(absolute_original_path) then
    utils.throw(("image.nvim: file not found: %s"):format(absolute_original_path))
  end

  -- bail if not an image
  if not utils.magic.is_image(absolute_original_path) then
    utils.debug(("image.nvim: not an image: %s"):format(absolute_original_path))
    return nil
  end

  -- bypass magick processing if already processed
  for _, instance in pairs(state.images) do
    if instance.original_path == absolute_original_path then
      local clone = createImage({
        id = opts.id or utils.random.id(),
        path = instance.path,
        resized_path = instance.path,
        cropped_path = instance.path,
        original_path = instance.original_path,
        image_width = instance.image_width,
        image_height = instance.image_height,
        window = opts.window or nil,
        buffer = opts.buffer or nil,
        geometry = {
          x = opts.x or 0,
          y = opts.y or 0,
          width = opts.width or nil,
          height = opts.height or nil,
        },
        rendered_geometry = {
          x = nil,
          y = nil,
          width = nil,
          height = nil,
        },
        with_virtual_padding = opts.with_virtual_padding or false,
        inline = opts.inline or opts.with_virtual_padding or false,
        is_rendered = false,
        crop_hash = nil,
        resize_hash = nil,
        namespace = opts.namespace or nil,
        last_modified = vim.fn.getftime(absolute_original_path),
      }, state)
      -- utils.debug(("image.nvim: cloned image %s from %s"):format(clone.id, instance.id))
      return clone
    end
  end

  local id = opts.id or utils.random.id()

  -- convert non-png images to png and read the dimensions
  local source_path = absolute_original_path
  local converted_path = state.tmp_dir .. "/" .. utils.base64.encode(id) .. "-source.png"
  local magick_image = nil

  -- case 1: non-png, already converted
  if
    vim.fn.filereadable(converted_path) == 1
    and vim.fn.getftime(converted_path) > vim.fn.getftime(absolute_original_path)
  then
    magick_image = magick.load_image(converted_path)
    source_path = converted_path
  else
    -- case 2: png
    magick_image = magick.load_image(absolute_original_path)

    -- case 3: non-png, not converted
    if magick_image:get_format():lower() ~= "png" then
      magick_image:set_format("png")
      magick_image:write(converted_path)
      source_path = converted_path
    end
  end

  if not magick_image then error(("image.nvim: magick failed to load image: %s"):format(absolute_original_path)) end
  local image_width = magick_image:get_width()
  local image_height = magick_image:get_height()
  magick_image:destroy()

  local instance = createImage({
    id = id,
    path = source_path,
    resized_path = source_path,
    cropped_path = source_path,
    original_path = path,
    image_width = image_width,
    image_height = image_height,
    window = opts.window or nil,
    buffer = opts.buffer or nil,
    geometry = {
      x = opts.x or 0,
      y = opts.y or 0,
      width = opts.width or nil,
      height = opts.height or nil,
    },
    rendered_geometry = {
      x = nil,
      y = nil,
      width = nil,
      height = nil,
    },
    with_virtual_padding = opts.with_virtual_padding or false,
    inline = opts.inline or opts.with_virtual_padding or false,
    is_rendered = false,
    crop_hash = nil,
    resize_hash = nil,
    namespace = opts.namespace or nil,
    last_modified = vim.fn.getftime(absolute_original_path),
  }, state)

  return instance
end

---@param url string
---@param options? ImageOptions
---@param callback fun(image: Image|nil)
---@param state State
local from_url = function(url, options, callback, state)
  if state.remote_cache[url] then
    local image = from_file(state.remote_cache[url], options, state)
    callback(image)
    return
  end

  local tmp_path = state.tmp_dir .. "/" .. utils.hash.sha256(url) .. ".png"
  local stdout = vim.loop.new_pipe()

  vim.loop.spawn("curl", {
    args = { "-L", "-s", "-o", tmp_path, url },
    stdio = { nil, stdout, nil },
    hide = true,
  }, function(code, signal)
    if code ~= 0 then
      utils.throw("image: curl errored while downloading " .. url, {
        code = code,
        signal = signal,
      })
      callback(nil)
    end
  end)

  vim.loop.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then utils.debug("image: downloaded " .. url .. " to " .. tmp_path) end
    state.remote_cache[url] = tmp_path

    vim.defer_fn(function()
      local ok, image = pcall(from_file, tmp_path, options, state)
      if ok then callback(image) end
    end, 0)
  end)
end

return {
  from_file = from_file,
  from_url = from_url,
}
