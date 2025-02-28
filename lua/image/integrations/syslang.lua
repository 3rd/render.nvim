local document = require("image/utils/document")

return document.create_document_integration({
  name = "syslang",
  -- debug = true,
  default_options = {
    clear_in_insert_mode = false,
    download_remote_images = true,
    only_render_image_at_cursor = false,
    floating_windows = false,
    filetypes = { "syslang" },
  },
  query_buffer_images = function(buffer)
    local buf = buffer or vim.api.nvim_get_current_buf()

    local parser = vim.treesitter.get_parser(buf, "syslang")
    local root = parser:parse()[1]:root()
    local query = vim.treesitter.query.parse("syslang", "(image (image_url) @url) @image")

    local images = {}
    local current_image = nil

    ---@diagnostic disable-next-line: missing-parameter
    for id, node in query:iter_captures(root, buf) do
      local key = query.captures[id]
      local value = vim.treesitter.get_node_text(node, buf)

      if key == "image" then
        local start_row, start_col, end_row, end_col = node:range()
        current_image = {
          node = node,
          range = { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col },
        }
      elseif current_image and key == "url" then
        current_image.url = value
        table.insert(images, current_image)
        current_image = nil
      end
    end

    return images
  end,
})
