local explorer = require('fzf-lua-explorer.explorer')

local M = {}

function M.setup(opts)
    opts = opts or {}
    
    vim.api.nvim_create_user_command('Explorer', function(args)
        local cmd_opts = {}
        if args.args and args.args ~= '' then
            cmd_opts.cwd = args.args
        end
        explorer.explorer(cmd_opts)
    end, {
        nargs = '?',
        complete = 'dir',
        desc = 'Open fzf-lua file explorer'
    })
    
    if opts.keymap ~= false then
        local key = opts.keymap or '<leader>e'
        vim.keymap.set('n', key, function()
            explorer.explorer()
        end, { desc = 'Open file explorer' })
    end
end

M.explorer = explorer.explorer

return M