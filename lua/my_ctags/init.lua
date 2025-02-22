local M = {}
local api = vim.api


---@return string[] 
local get_files_in_pwd = function()
  local curr_dir = api.nvim_exec2("pwd", {output = true}).output
  local ls_output = api.nvim_exec2("!ls -R " .. curr_dir, {output = true}).output

  local filepaths_raw = {}
  for fp in ls_output:gmatch("[/%w_%-%.]+") do 
    if (fp ~= 'ls' and fp ~= '-R') then 
      table.insert(filepaths_raw, fp) 
    end
  end

  local i = 1
  local curr_path = ""
  local filepaths = {}

  while i < #filepaths_raw + 1 do
    if filepaths_raw[i]:match("/") ~= nil then
      curr_path = filepaths_raw[i]
    elseif filepaths_raw[i]:match("%w+%.[ch]") ~= nil then
      table.insert(filepaths, curr_path .. "/" .. filepaths_raw[i])
    end
    i = i + 1
  end

  return filepaths
end


local func =  "([%w+_*]+)%s*%([%w*%**%s*,*%_*]+%)[\n]?%{" 
local macro = "#define%s*([%w*_*]+)"
local typedefed_struct = "%}%s*([%w*_*]+)%;"

---@return {[string]: (string | number)}
local search_defs = function()
  local filepaths = get_files_in_pwd()
  local defs_hooks = {}

  for _, at_file in ipairs(filepaths) do
    io.input(at_file)
    local file = io.read("*all")
    local at_line = 0
    local last_line_end = 1
    local char_offset = 0

    -- NOTE: for some reason io.lines() skips the first line of the 2nd file in the table, that's 
    -- why i'm loopin through each char
    
    for char in file:gmatch(".") do
      char_offset = char_offset + 1

      if char == '\n' then
        at_line = at_line + 1
        local line = file:sub(last_line_end, char_offset + 1)
        local def_name = line:match(func) or line:match(macro) or line:match(typedefed_struct)
        last_line_end = char_offset

        -- NOTE+TODO: if in your codebase there are some unused files
        -- and they contain declarations with the same name as somthing
        -- declared in a used file, there is a chance the hook could be overwritten.
        -- At the moment I'm just checking if i haven't already met something
        -- with the same name, but that's still unsafe as the order of 
        -- parsing is basically random for what i know. 
        -- I think there should be a chance
        -- of specifying certain folders or files that should not get searched.
        if def_name ~= nil and defs_hooks[def_name] == nil then
          defs_hooks[def_name] = {at_file, at_line}
        end
      end
    end
  end
  return defs_hooks
end

M.jump_to_def = function()
  local word_at_curs = vim.fn.expand("<cword>")
  M.defs_hooks = search_defs()

  if M.defs_hooks[word_at_curs] ~= nil then
    vim.cmd("edit " .. M.defs_hooks[word_at_curs][1])
    vim.fn.cursor(M.defs_hooks[word_at_curs][2], 0)
  else
    vim.notify('no defintion found for: ' .. word_at_curs, vim.log.levels.ERROR)
  end
end



return M
