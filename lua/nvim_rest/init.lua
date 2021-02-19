require("plenary.reload").reload_module("nvim_rest")
local curl = require("plenary.curl")
local api = vim.api
local utils = require("nvim_rest.utils")

local function get_or_create_buf()
  local tmp_name = "nvim_rest_results"

  -- check if the file already loaded in the buffer
  local existing_bufnr = vim.fn.bufnr(tmp_name)
  if existing_bufnr > -1 then
    -- delete the content
    api.nvim_buf_set_lines(
      existing_bufnr,
      0,
      api.nvim_buf_line_count(existing_bufnr) - 1,
      false,
      {}
    )

    -- make sure of filetype is json
    api.nvim_buf_set_option(existing_bufnr, "ft", "json")

    return existing_bufnr
  end

  local new_bufnr = api.nvim_create_buf(false, "nomodified")
  api.nvim_buf_set_name(new_bufnr, tmp_name)
  api.nvim_buf_set_option(new_bufnr, "ft", "json")

  return new_bufnr
end

local function get()
  local line = vim.fn.getline(".")
  local res = curl.get(line)
  local bufnr = get_or_create_buf()

  -- add the curl result into the created buffer
  for l in utils.magiclines(res.body) do
    local line_count = api.nvim_buf_line_count(bufnr) - 1
    api.nvim_buf_set_lines(bufnr, line_count, line_count, false, {l})
  end

  -- only open new split if the buffer not loaded into the current window
  if vim.fn.bufwinnr(bufnr) == -1 then
    vim.cmd([[vert sb]] .. bufnr)
  end
end

api.nvim_set_keymap(
  "n",
  ",w",
  ":lua require('nvim_rest').get()<cr>",
  {noremap = true, silent = true}
)

return {
  get = get
}
