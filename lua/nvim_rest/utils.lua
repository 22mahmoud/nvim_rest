local M = {}

M.magiclines = function(s)
  if s:sub(-1) ~= "\n" then
    s = s .. "\n"
  end
  return s:gmatch("(.-)\n")
end

return M
