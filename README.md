# my_ctags.nvim

Jump to definitions WITHOUT tags, all in Lua. That's it.

No need for external programs or anything.

# Why
I have no idea how to use Neovim's tags and no idea why you need 
to install a separate program for to make them (not throwing shades, im genuinely dumb caveman brain and shit).

I made it for me, so it's probably not even the best implementation in the world.

# WARNING 
I have no idea how performant it is on large codebases, so
keep your expectations low pls. 

# Install
Make a '''my_ctags.lua''' file in your plugin-folder, copy 
paste this and your good to go.

```lua
return {
    "francescoApophis/my_ctags.nvim",
    lazy = false,
    config = function()
        local my_ctags = require("my_ctags")
        vim.keymap.set('n', 'your key', my_ctags.jump_to_def, {silent = true, noremap = true})
    end
}
```

# Extendability
At the moment it only supports *.c* and *.h*, as the name implies and also
because that's what I need, but there is no reason it should not be able to 
support other languages as well since it uses Lua's searching patterns to do its job. 

If you want to you could clone the repo and modify the 
'''my_ctags.lua''' file in your plugin-folder to:

```lua
return {
    dir = "path/where/you/cloned/my_ctags.nvim",
    lazy = false,
    config = function()
        local my_ctags = require("my_ctags")
        vim.keymap.set('n', 'your key', my_ctags.jump_to_def, {silent = true, noremap = true})
    end
}
```

At this point just add more patterns like '''func''' or '''typdefed_struct''' in the '''init.lua''' following how the defintion of something in your target-language works.

