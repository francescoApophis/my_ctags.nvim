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

# Requirements
Neovim v0.9.5 >= (haven't tested it on next versions).

Since it relies on ```pwd``` and on the output of ```ls -R```, 
I guess it will only work properly on Linux.


# Install and usage
Make a '''my_ctags.lua''' file in your plugin-folder, copy 
paste this and your good to go.

```lua
return {
    "francescoApophis/my_ctags.nvim",
    lazy = false,
    config = function()
        local my_ctags = require("my_ctags")
        vim.keymap.set('n', 'your remap', my_ctags.jump_to_def, {silent = true, noremap = true})
        -- OR: 
        -- this remap will search for all the definitions every time, this is by default
        vim.keymap.set('n', 'your remap', function() my_ctags.jump_to_def(true) end, {silent = true, noremap = true})
        -- this remap will use the definitions found during the last search
        vim.keymap.set('n', 'your remap', function() my_ctags.jump_to_def(false) end, {silent = true, noremap = true})
    end
}
```

You can specify paths (folders, specific files or both) **to be ignored** when searching.
This means that you will not be able to jump to a definition that's located in
one of this files.

Just call ```:require('my_ctags').set_filepaths_to_ignore(filepaths)``` where ```filepaths``` is
either a ```string``` or an array of strings. The next search will make sure to ignore them.

***Make sure a path is a full path or that it uses the '~'.***

You can see all ignored paths by calling ```:require('my_ctags').get_filepaths_ignored()```

This is useful if you have files that unused files that may contain 
definitions that share the same name with other *used* definitions.


# Extendability
At the moment it only supports *.c* and *.h*, as the name implies and also
because that's what I need, but there is no reason it should not be able to 
support other languages as well since it uses Lua's searching patterns to do its job. 

If you want to you could clone the repo and modify the 
```my_ctags.lua``` file in your plugin-folder to:

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

At this point just add more patterns like ```func``` or ```typdefed_struct``` in the ```init.lua``` following how the defintion of something in your target-language works.

