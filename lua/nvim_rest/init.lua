require("plenary.reload").reload_module("nvim_rest")
local _curl = require("plenary.curl")
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

  local new_bufnr = api.nvim_create_buf(false, "nomodeline")
  api.nvim_buf_set_name(new_bufnr, tmp_name)
  api.nvim_buf_set_option(new_bufnr, "ft", "json")

  return new_bufnr
end

local function parse_url(str)
  local parsed = utils.split(str, " ")
  return {method = parsed[1], url = parsed[2]}
end

local function go_to_line(bufnr, line)
  api.nvim_buf_call(
    bufnr,
    function()
      vim.fn.cursor(line, 1)
    end
  )
end

local function get_json(term, bufnr, stopline, queryline)
  local json = nil
  local start_line = vim.fn.search(term .. " {", "", stopline)
  local end_line = vim.fn.search("}", "n", stopline)

  if (start_line > 0) then
    local json_string = ""
    local json_lines =
      api.nvim_buf_get_lines(bufnr, start_line, end_line - 1, false)
    for _, v in ipairs(json_lines) do
      json_string = json_string .. v
    end

    json_string = "{" .. json_string .. "}"

    json = vim.fn.json_decode(json_string)
  end

  go_to_line(bufnr, queryline)
  return json
end

local function curl(opts)
  local res = _curl[opts.method](opts)
  local res_bufnr = get_or_create_buf()

  -- add the curl result into the created buffer
  for l in utils.magiclines(res.body) do
    local line_count = api.nvim_buf_line_count(res_bufnr) - 1
    api.nvim_buf_set_lines(res_bufnr, line_count, line_count, false, {l})
  end

  -- only open new split if the buffer not loaded into the current window
  if vim.fn.bufwinnr(res_bufnr) == -1 then
    vim.cmd([[vert sb]] .. res_bufnr)
  end

  api.nvim_buf_call(
    res_bufnr,
    function()
      vim.fn.cursor(1, 1)
    end
  )
end

local function run()
  local bufnr = api.nvim_win_get_buf(0)
  local parsed_url = parse_url(vim.fn.getline("."))
  local last_query_line_number = vim.fn.line(".")

  local next_query =
    vim.fn.search("GET\\|POST\\|PUT\\|PATCH\\|DELETE", "n", vim.fn.line("$"))
  next_query = next_query > 1 and next_query or vim.fn.line("$")

  local query = get_json("QUERY", bufnr, next_query, last_query_line_number)
  local headers = get_json("HEADERS", bufnr, next_query, last_query_line_number)
  local body = get_json("BODY", bufnr, next_query, last_query_line_number)

  curl(
    {
      method = parsed_url.method:lower(),
      url = parsed_url.url,
      query = query,
      headers = headers,
      body = body
    }
  )

  go_to_line(bufnr, last_query_line_number)
end

api.nvim_set_keymap(
  "n",
  ",w",
  ":lua require('nvim_rest').run()<cr>",
  {noremap = true, silent = true}
)

return {
  run = run
}
