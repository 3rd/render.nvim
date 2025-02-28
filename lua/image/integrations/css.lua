local document = require("image/utils/document")
return document.create_document_integration({
  name = "css",
  -- debug = true,
  default_options = {
    clear_in_insert_mode = false,
    download_remote_images = true,
    only_render_image_at_cursor = false,
    floating_windows = false,
    filetypes = { "css", "sass", "scss" },
  },
  query_buffer_images = function(buffer)
    local buf = buffer or vim.api.nvim_get_current_buf()

    local parser = vim.treesitter.get_parser(buf, "css")
    local root = parser:parse()[1]:root()
    local query = vim.treesitter.query.parse(
      "css",
      '(call_expression (function_name) @name (#eq? @name "url"))'
    )

    local images = {}

    ---@diagnostic disable-next-line: missing-parameter
    for id, node in query:iter_captures(root, buf) do
      local capture = query.captures[id]

      if capture == "name" then
        ---@diagnostic disable-next-line: unused-local
        local start_row, start_col, end_row, end_col = node:range()
        local line = vim.api.nvim_buf_get_lines(
          buf,
          end_row,
          end_row + 1,
          false
        )[1]

        local path = line:sub(start_col):gsub(".*url%([\"'](.-)[\"']%).*$", "%1")

        -- search for path relative to webroot
        if path:sub(1,1) == "/" then
          path = vim.fs.find(path:sub(2), {
            upward = true,
            path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
          })[1]
        end

        if path ~= nil then
          table.insert(images, {
            node = node,
            range = {
              start_row = start_row,
              start_col = start_col,
              end_row = end_row,
              end_col = end_col,
            },
            url = path,
          })
        end
      end
    end

    return images
  end
})
