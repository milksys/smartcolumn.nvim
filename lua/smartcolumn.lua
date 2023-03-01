local smartcolumn = {}

local config = {
   colorcolumn = "80",
   disabled_filetypes = { "help", "text", "markdown" },
   custom_colorcolumn = {},
   scope = "file",
}

local function is_disabled()
   local current_filetype = vim.api.nvim_buf_get_option(0, "filetype")
   for _, filetype in pairs(config.disabled_filetypes) do
      if filetype == current_filetype then
         return true
      end
   end
   return false
end

local function detect()
   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true) -- file scope
   if config.scope == "line" then
      lines = { vim.api.nvim_get_current_line() }
   elseif config.scope == "window" then
      lines = vim.api.nvim_buf_get_lines(0, vim.fn.line("w0")-1,
         vim.fn.line("w$"), true)
   end

   local max_column = 0
   for _, line in pairs(lines) do
      max_column = math.max(max_column, vim.fn.strdisplaywidth(line))
   end

   local buf_filetype = vim.api.nvim_buf_get_option(0, "filetype")
   local colorcolumns =
      config.custom_colorcolumn[buf_filetype] or config.colorcolumn

   local min_colorcolumn = colorcolumns
   if type(colorcolumns) == "table" then
      min_colorcolumn = colorcolumns[1]
      for _, colorcolumn in pairs(colorcolumns) do
         min_colorcolumn = math.min(min_colorcolumn, colorcolumn)
      end
   end
   min_colorcolumn = tonumber(min_colorcolumn)

   local current_buf = vim.api.nvim_get_current_buf()
   local windows = vim.api.nvim_list_wins()
   for _, window in pairs(windows) do
      if vim.api.nvim_win_get_buf(window) == current_buf then
         if not is_disabled() and max_column > min_colorcolumn then
            vim.opt.colorcolumn = colorcolumns
         else
            vim.opt.colorcolumn = nil
         end
      end
   end
end

function smartcolumn.setup(user_config)
   user_config = user_config or {}

   for option, value in pairs(user_config) do
      config[option] = value
   end

   vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "CursorMovedI" },
      { callback = detect })
end

return smartcolumn
