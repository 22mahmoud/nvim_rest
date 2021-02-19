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

local function get(opts)
  local url = opts.url
  local query = opts.query

  local res =
    curl.get(
    {
      url = url,
      query = query
    }
  )
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

local function start()
  local line = utils.split(vim.fn.getline("."), " ")
  local method, url = line[1], line[2]

  if method == "GET" then
    local bufnr = api.nvim_win_get_buf(0)
    local next_query = vim.fn.search("GET", "n", vim.fn.line("$"))
    print(next_query)
    local start_query_line_number =
      vim.fn.search("{", "n", next_query > 1 and next_query or vim.fn.line("$"))
    local end_query_line_number =
      vim.fn.search("}", "n", next_query > 1 and next_query or vim.fn.line("$"))
    local query = nil
    if (start_query_line_number > 0) then
      local query_string = ""
      local query_lines =
        api.nvim_buf_get_lines(
        bufnr,
        start_query_line_number - 1,
        end_query_line_number,
        false
      )
      for _, v in ipairs(query_lines) do
        query_string = query_string .. v
      end

      query = vim.fn.json_decode(query_string)
    end
    get({url = url, query = query})
  end
end

api.nvim_set_keymap(
  "n",
  ",w",
  ":lua require('nvim_rest').start()<cr>",
  {noremap = true, silent = true}
)

return {
  get = get,
  start = start
}
