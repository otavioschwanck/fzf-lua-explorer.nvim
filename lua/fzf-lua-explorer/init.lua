local explorer = require('fzf-lua-explorer.explorer')

local M = {}

-- Default configuration
local default_config = {
    keybindings = {
        create_file = 'ctrl-a',
        rename_file = 'ctrl-r',
        cut_files = 'ctrl-x',
        copy_files = 'ctrl-y',
        paste_files = 'ctrl-v',
        clean_clipboard = 'ctrl-e',
        go_to_cwd = 'ctrl-g',
        find_folders = 'ctrl-f',
        delete_files = 'del'
    },
    show_icons = true,
    clipboard_buffer = {
        enabled = true,          -- Show clipboard buffer
        min_width = 40,          -- Minimum width of clipboard buffer
        max_width = 80,          -- Maximum width of clipboard buffer
        height = 10,             -- Height of clipboard buffer
        row = 2,                 -- Row position (from top)
        col_offset = 2,          -- Offset from right edge
        border = 'rounded'       -- Border style
    }
}

-- Store configuration globally so explorer can access it
M.config = vim.deepcopy(default_config)

function M.setup(opts)
    opts = opts or {}
    
    -- Merge user configuration with defaults
    M.config = vim.tbl_deep_extend('force', default_config, opts)
    
    -- Set the configuration in explorer module
    explorer.set_config(M.config)
    
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