local M = {}
local api = vim.api

local _print = function(i)
  print((type(i) ~= 'table' and i) or vim.inspect(i)) 
end


local func = '[%w+_*%**]+%s+(%**[%w+_*]+)%s*%([%w*%**%s*,*%_*]*%)[\n]?%{'
local macro = '#define%s*([%w*_*]+)'
local typedefed_struct = '%}%s*([%w*_*]+)%;'
-- TODO: add non typedefed struct

M.defs_hooks = {}
M.filepaths_to_ignore = {}
local prev_bufnr, prev_curs_row, prev_curs_col = -1, -1, -1



---@param filepaths string[]  they can indicate folders or specific files
M.set_filepaths_to_ignore = function(filepaths)
  local t = type(filepaths)
  if t ~= 'string' and t ~= 'table' then
    vim.notify('invalid filepath. Please use a string or an array of strings', vim.log.levels.ERROR)
    return nil
  end

  if t == 'string' then
    filepaths = filepaths == '' and {} or {filepaths}
  end

  local expanded = {}
  for _, i in ipairs(filepaths) do
    if i ~= '' then 
      table.insert(expanded, vim.fn.expand(i))
    end
  end

  M.filepaths_to_ignore = expanded
end

M.get_filepaths_ignored = function()
  for _, i in ipairs(M.filepaths_to_ignore) do
    print(i)
  end
end 

---@return boolean 
local to_ignore = function(path)
  for _, ignored in ipairs(M.filepaths_to_ignore) do
    if path:find(ignored, 1, true) ~= nil then return true end
  end
  return false
end

---@return string[] 
local get_files_in_pwd = function()
  local curr_dir = api.nvim_exec2('pwd', {output = true}).output
  local ls_output_raw = api.nvim_exec2("!ls -R " .. curr_dir, {output = true}).output

  -- TODO: sometimes i open files that are not in the pwd.
  -- Check and add open buffers
  local ls_output = {}
  for i in ls_output_raw:gmatch('[/%w_%-%.]+') do 
    if (i ~= 'ls' and i ~= '-R') then 
      table.insert(ls_output, i) 
    end
  end

  local curr_path = ''
  local ignore_path = false
  local filepaths = {}

  for _, i in ipairs(ls_output) do
    if i:match('/') ~= nil then
      ignore_path = to_ignore(i)
      curr_path = i
    elseif i:match('%w+%.[ch]') ~= nil and not ignore_path then
      local file = curr_path .. '/' .. i
      if not to_ignore(file) then
        table.insert(filepaths, file)
      end
    end
  end
  return filepaths
end



---@return string | nil Returns the defintion's name
local match_def = function(line)
  return line:match(func) or 
         line:match(macro) or 
         line:match(typedefed_struct)
end


---@return {[string]: (string | number)}
local search_defs = function()
  local filepaths = get_files_in_pwd()
  local defs_hooks = {}

  local next = next
  if (next(filepaths) == nil) then return nil end

  for _, at_file in ipairs(filepaths) do
    io.input(at_file)
    local file = io.read('*all')
    local at_line, char_offset, last_line_end = 0, 0, 1

    for char in file:gmatch('.') do
      char_offset = char_offset + 1

      if char == '\n' then
        at_line = at_line + 1
        local line = file:sub(last_line_end, char_offset + 1)
        local def_name = match_def(line)
        last_line_end = char_offset
        if def_name ~= nil then
          defs_hooks[def_name] = {at_file, at_line}
        end
      end
    end
  end
  return defs_hooks
end



M.jump_back = function() 
  if prev_buf == -1 or prev_curs_row == -1 or  prev_curs_col == -1 then
    vim.notify('my_ctags.nvim: you haven\'t jumped to any definition, no place to go back to.', vim.log.levels.ERROR)
    return
  end
  -- If you inadvertently press your jump-back key and you go to 
  -- a jump-to-def's previous location, you can go back to where 
  -- you were by pressing it again.
  local curr_bufnr = vim.fn.bufnr(vim.fn.bufname())
  local curr_curs = vim.fn.getcursorcharpos(vim.fn.winnr())

  vim.cmd('buf ' .. tostring(prev_bufnr))
  vim.fn.setcursorcharpos(prev_curs_row, prev_curs_col)

  prev_bufnr = curr_bufnr
  prev_curs_row, prev_curs_col = curr_curs[2], curr_curs[3]
end


---@return nil
M.jump_to_def = function(new_search)
  new_search = new_search ~= nil or true

  local word_at_curs = vim.fn.expand('<cword>')
  if new_search then
    M.defs_hooks = search_defs()
  end

  if M.defs_hooks == nil then
    vim.notify('my_ctags.nvim: zero definition to jump to. Check if you haven\'t added the file containing the definition in "filepaths_to_ignore"', vim.log.levels.ERROR)
    return
  end

  if M.defs_hooks[word_at_curs] ~= nil then
    local bufnr = vim.fn.bufadd(M.defs_hooks[word_at_curs][1])
    if not vim.fn.bufloaded(bufnr) then
      vim.fn.bufload(bufnr)
    end

    prev_bufnr = vim.fn.bufnr(vim.fn.bufname())
    local prev_curs = vim.fn.getcursorcharpos(vim.fn.winnr())
    prev_curs_row, prev_curs_col = prev_curs[2], prev_curs[3]

    vim.cmd('buf ' .. tostring(bufnr))
    vim.fn.setcursorcharpos(M.defs_hooks[word_at_curs][2], 0)
  else
    vim.notify('No definition to jump to found for: ' .. word_at_curs .. '. Check if you haven\'t added the file containing the defintion in "filepaths_to_ignore"', vim.log.levels.ERROR)
  end
end


return M
