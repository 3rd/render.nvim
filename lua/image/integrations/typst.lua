local document = require("image/utils/document")
return document.create_document_integration({
  name = "typst",
  -- debug = true,
  default_options = {
    clear_in_insert_mode = false,
    download_remote_images = true,
    only_render_image_at_cursor = false,
    floating_windows = false,
    filetypes = { "typst" },
  },
  query_buffer_images = function(buffer)
    local buf = buffer or vim.api.nvim_get_current_buf()

    local parser = vim.treesitter.get_parser(buf, "typst")
    local root = parser:parse()[1]:root()
    local query =
      vim.treesitter.query.parse("typst", '(call item: (ident) @name (#eq? @name "image") (group (string) @url))')

    local images = {}
    local current_image = nil

    ---@diagnostic disable-next-line: missing-parameter
    for id, node in query:iter_captures(root, buf) do
      local capture = query.captures[id]
      local value = vim.treesitter.get_node_text(node, buf)

      if capture == "name" then
        -- Get the parent since we want the "call" and not only the "ident"
        local start_row, start_col, end_row, end_col = node:parent():range()
        current_image = {
          node = node,
          range = { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col },
        }
      elseif current_image and capture == "url" then
        -- We need to remove the quotes from the string
        -- '"The URL"' -> "The URL"
        current_image.url = string.sub(value, 2, -2)

        table.insert(images, current_image)
        current_image = nil
      end
    end

    return images
  end,
})
