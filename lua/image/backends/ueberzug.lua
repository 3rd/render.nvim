local utils = require("image/utils")

local child = nil
local should_be_alive = false

local spawn = function()
  local stdin = vim.loop.new_pipe()
  local stdout = vim.loop.new_tty(1, false)
  local stderr = vim.loop.new_pipe()
  should_be_alive = true

  local handle, pid = vim.loop.spawn("ueberzug", {
    args = { "layer", "--silent" },
    stdio = { stdin, stdout, stderr },
  }, function(code, signal)
    child = nil
    if should_be_alive then
      utils.throw("image: ueberzug died unexpectedly", {
        code = code,
        signal = signal,
      })
    end
  end)

  if not handle then error("image: failed to spawn ueberzug") end
  if not stdin then error("image: failed to open stdin") end

  local write = function(data)
    local serialized = vim.fn.json_encode(data)
    -- utils.debug("ueberzug:stdin", serialized)
    vim.loop.write(stdin, serialized .. "\n")
  end

  local shutdown = function()
    should_be_alive = false
    vim.loop.shutdown(stdin, function()
      vim.loop.close(handle, function() end)
    end)
  end

  child = {
    handle = handle,
    pid = pid,
    stdin = stdin,
    write = write,
    shutdown = shutdown,
  }
end

---@type Backend
---@diagnostic disable-next-line: missing-fields
local backend = {
  ---@diagnostic disable-next-line: assign-type-mismatch
  state = nil,
  features = {
    crop = false,
  },
}

backend.setup = function(state)
  backend.state = state
  if not child then spawn() end
end

backend.render = function(image, x, y, width, height)
  if not child then return end
  child.write({
    action = "add",
    identifier = image.id,
    path = image.cropped_path,
    x = x,
    y = y,
    width = width,
    height = height,
  })
  image.is_rendered = true
  backend.state.images[image.id] = image
end

backend.clear = function(image_id, shallow)
  if not child then return end

  -- one
  if image_id then
    local image = backend.state.images[image_id]
    if not image then return end
    child.write({
      action = "remove",
      identifier = image_id,
    })
    image.is_rendered = false
    if not shallow then backend.state.images[image_id] = nil end
    return
  end

  -- all
  for id, image in pairs(backend.state.images) do
    child.write({
      action = "remove",
      identifier = id,
    })
    image.is_rendered = false
    if not shallow then backend.state.images[id] = nil end
  end
end

return backend
