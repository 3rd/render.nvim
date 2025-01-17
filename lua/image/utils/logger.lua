local defaults = {
  handler = nil,
  output_file = nil,
  prefix = "",
}

local is_primitive = function(value)
  return type(value) == "string" or type(value) == "number" or type(value) == "boolean"
end

local is_func = function(value)
  return type(value) == "function"
end

local base_hrtime = vim.loop.hrtime()
local get_highres_time = function()
  local elapsed_ns = vim.loop.hrtime() - base_hrtime
  local elapsed_s = elapsed_ns / 1e9
  local time_s = os.time() + math.floor(elapsed_s)
  local frac_s = elapsed_s % 1
  return string.format("%s.%06d", os.date("%H:%M:%S", time_s), math.floor(frac_s * 1e6))
end

local default_log_formatter = function(opts, ...)
  local parts = {}
  parts[#parts + 1] = get_highres_time()
  if opts.prefix then parts[#parts + 1] = opts.prefix end
  for _, v in ipairs({ ... }) do
    local format_handler = nil
    if not is_primitive(v) then
      format_handler = vim.inspect
    else
      format_handler = tostring
    end
    parts[#parts + 1] = format_handler(v)
  end
  return table.concat(parts, " ")
end

local create_logger = function(options)
  local opts = vim.tbl_deep_extend("force", defaults, options or {})

  return function(...)
    local output = opts.formatter and opts.formatter(opts, ...) or { ... }

    if opts.output_file then
      local handle = io.open(opts.output_file, "a")
      if handle then
        handle:write(output .. "\n")
        handle:close()
      end
    end

    if is_func(opts.handler) then opts.handler(output) end
  end
end

return {
  create_logger = create_logger,
  default_log_formatter = default_log_formatter,
  log = create_logger({
    prefix = "[image.nvim]",
    formatter = default_log_formatter,
    handler = print,
    output_file = "/tmp/nvim-image.txt",
  }),
  throw = create_logger({
    prefix = "[image.nvim]",
    formatter = default_log_formatter,
    handler = error,
    output_file = "/tmp/nvim-image.txt",
  }),
  debug = create_logger({
    prefix = "[image.nvim]",
    formatter = default_log_formatter,
    handler = print,
    output_file = "/tmp/nvim-image.txt",
  }),
}
