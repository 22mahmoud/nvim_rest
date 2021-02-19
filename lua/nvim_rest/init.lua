require("plenary.reload").reload_module("nvim_rest")
local curl = require("plenary.curl")
local api = vim.api
local utils = require("nvim_rest.utils")

local bufnr = nil

local function greet()
  local line = vim.fn.getline(".")
  local res = curl.get(line)

  bufnr = bufnr or api.nvim_create_buf("on", "nomodified")
  api.nvim_buf_set_name(bufnr, "result.json")
  api.nvim_buf_set_option(bufnr, "ft", "json")

  if api.nvim_buf_line_count(bufnr) >= 1 then
    api.nvim_buf_set_lines(
      bufnr,
      0,
      api.nvim_buf_line_count(bufnr) - 1,
      false,
      {}
    )
  end

  for l in utils.magiclines(res.body) do
    local line_count = api.nvim_buf_line_count(bufnr) - 1
    api.nvim_buf_set_lines(bufnr, line_count, line_count, false, {l})
  end

  if vim.fn.bufwinnr(bufnr) == -1 then
    vim.cmd([[vert sb]] .. bufnr)
  end
end

api.nvim_set_keymap(
  "n",
  ",w",
  ":lua require('nvim_rest').greet()<cr>",
  {noremap = true, silent = true}
)

return {
  greet = greet
}
