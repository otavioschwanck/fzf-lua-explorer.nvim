local fzf = require('fzf-lua')
local core = require('fzf-lua.core')
local config = require('fzf-lua.config')
local make_entry = require('fzf-lua.make_entry')
local path = require('fzf-lua.path')
local utils = require('fzf-lua.utils')
local actions = require('fzf-lua.actions')

local function get_icon(filename, is_directory)
    local ok, devicons = pcall(require, 'nvim-web-devicons')
    if ok then
        if is_directory then
            return '📁'
        else
            local icon, hl = devicons.get_icon(filename, vim.fn.fnamemodify(filename, ':e'), { default = true })
            return icon or '📄'
        end
    else
        if is_directory then
            return '📁'
        else
            return '📄'
        end
    end
end

local M = {}

local explorer_state = {
    current_dir = nil,
    cut_files = {},
    copy_files = {},
    operation = nil,
    clipboard_win = nil,
    clipboard_buf = nil
}

-- Extract filename from make_entry.file formatted entry
local function extract_filename(entry)
    if type(entry) ~= "string" then
        return entry
    end
    
    -- Remove ANSI escape codes and extract filename
    -- Pattern: \27[...m icon \27[0m filename
    local cleaned = entry:gsub('\27%[[0-9;]*m', '')  -- Remove all ANSI codes
    
    -- The cleaned string should be: icon + space + filename
    -- Extract everything after the icon and space
    local filename = cleaned:match('^.%s(.+)$')
    if filename then
        return filename
    end
    
    -- Fallback: extract just alphabetic/numeric filename part
    local fallback = cleaned:match('([%w%./_-]+)$')
    return fallback or entry
end

-- Create floating buffer to show clipboard status
local function create_clipboard_buffer()
    if explorer_state.clipboard_win and vim.api.nvim_win_is_valid(explorer_state.clipboard_win) then
        return  -- Already exists
    end
    
    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    explorer_state.clipboard_buf = buf
    
    -- Buffer settings
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'fzf-lua-explorer-clipboard')
    
    -- Window configuration
    local width = 40
    local height = 10
    local row = 2
    local col = vim.o.columns - width - 2
    
    local win_config = {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        border = 'rounded',
        style = 'minimal',
        title = ' Clipboard ',
        title_pos = 'center',
        zindex = 1000  -- High z-index to stay on top
    }
    
    -- Create window
    local win = vim.api.nvim_open_win(buf, false, win_config)
    explorer_state.clipboard_win = win
    
    -- Window settings
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')
    vim.api.nvim_win_set_option(win, 'wrap', false)
    vim.api.nvim_win_set_option(win, 'cursorline', false)
    
    return buf, win
end

-- Update clipboard buffer content
local function update_clipboard_buffer()
    if not explorer_state.clipboard_buf or not vim.api.nvim_buf_is_valid(explorer_state.clipboard_buf) then
        return
    end
    
    -- Make buffer modifiable
    vim.api.nvim_buf_set_option(explorer_state.clipboard_buf, 'modifiable', true)
    
    local lines = {}
    local has_content = false
    
    -- Add cut files
    if #explorer_state.cut_files > 0 then
        table.insert(lines, '✂️  Cut Files:')
        for _, file in ipairs(explorer_state.cut_files) do
            -- Show path relative to current working directory
            local display_path = path.relative_to(file, vim.fn.getcwd()) or file
            table.insert(lines, '  ' .. display_path)
        end
        table.insert(lines, '')
        has_content = true
    end
    
    -- Add copy files
    if #explorer_state.copy_files > 0 then
        table.insert(lines, '📋 Copy Files:')
        for _, file in ipairs(explorer_state.copy_files) do
            -- Show path relative to current working directory
            local display_path = path.relative_to(file, vim.fn.getcwd()) or file
            table.insert(lines, '  ' .. display_path)
        end
        table.insert(lines, '')
        has_content = true
    end
    
    -- Add instructions
    if has_content then
        table.insert(lines, 'Press Ctrl+v to paste')
    else
        table.insert(lines, 'No files in clipboard')
        table.insert(lines, '')
        table.insert(lines, 'Ctrl+x: Cut files')
        table.insert(lines, 'Ctrl+y: Copy files')
    end
    
    -- Update buffer content
    vim.api.nvim_buf_set_lines(explorer_state.clipboard_buf, 0, -1, false, lines)
    
    -- Set buffer as unmodifiable
    vim.api.nvim_buf_set_option(explorer_state.clipboard_buf, 'modifiable', false)
end

-- Show clipboard buffer
local function show_clipboard_buffer()
    create_clipboard_buffer()
    update_clipboard_buffer()
end

-- Bring clipboard buffer to front
local function bring_clipboard_to_front()
    if explorer_state.clipboard_win and vim.api.nvim_win_is_valid(explorer_state.clipboard_win) then
        -- Close existing window
        vim.api.nvim_win_close(explorer_state.clipboard_win, true)
        explorer_state.clipboard_win = nil
    end
    -- Recreate to bring to front
    show_clipboard_buffer()
end

-- Hide clipboard buffer
local function hide_clipboard_buffer()
    if explorer_state.clipboard_win and vim.api.nvim_win_is_valid(explorer_state.clipboard_win) then
        vim.api.nvim_win_close(explorer_state.clipboard_win, true)
        explorer_state.clipboard_win = nil
    end
    if explorer_state.clipboard_buf and vim.api.nvim_buf_is_valid(explorer_state.clipboard_buf) then
        vim.api.nvim_buf_delete(explorer_state.clipboard_buf, { force = true })
        explorer_state.clipboard_buf = nil
    end
end

local function get_current_file_dir()
    local current_file = vim.fn.expand('%:p')
    if current_file == '' then
        return vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
    end
    return vim.fn.fnamemodify(current_file, ':p:h')
end

local function get_file_type(file_path)
    local stat = vim.loop.fs_stat(file_path)
    if stat then
        return stat.type
    end
    return nil
end

local function get_files_in_dir(dir)
    local files = {}
    local handle = vim.loop.fs_scandir(dir)
    if handle then
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end
            
            local full_path = path.join({dir, name})
            local display_name = name
            
            if type == 'directory' then
                display_name = name .. '/'
            end
            
            table.insert(files, {
                name = display_name,
                path = full_path,
                type = type
            })
        end
    end
    
    table.sort(files, function(a, b)
        if a.type == 'directory' and b.type ~= 'directory' then
            return true
        elseif a.type ~= 'directory' and b.type == 'directory' then
            return false
        else
            return a.name < b.name
        end
    end)
    
    if dir ~= '/' then
        table.insert(files, 1, {
            name = '../',
            path = vim.fn.fnamemodify(dir, ':h'),
            type = 'directory'
        })
    end
    
    return files
end

local function create_file_action(opts)
    return function()
        local current_dir = explorer_state.current_dir
        local clean_dir = vim.fn.fnamemodify(current_dir, ':p')
        
        vim.ui.input({
            prompt = 'Create file: ',
            default = clean_dir
        }, function(input)
            if input and input ~= '' then
                local file_path = input
                
                if not vim.startswith(file_path, '/') then
                    file_path = path.join({clean_dir, file_path})
                end
                
                file_path = vim.fn.fnamemodify(file_path, ':p')
                
                local dir = vim.fn.fnamemodify(file_path, ':h')
                vim.fn.mkdir(dir, 'p')
                
                local file = io.open(file_path, 'w')
                if file then
                    file:close()
                    vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
                else
                    vim.notify('Failed to create file: ' .. file_path, vim.log.levels.ERROR)
                end
            end
        end)
    end
end

local function rename_file_action(opts)
    return function(selected)
        local files_to_rename = {}
        
        if selected and #selected > 0 then
            for _, sel in ipairs(selected) do
                local file_info = extract_filename(sel)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_rename, file_info)
                end
            end
        else
            local current_entry = opts.current_entry
            if current_entry then
                local file_info = extract_filename(current_entry)
                table.insert(files_to_rename, file_info)
            end
        end
        
        if #files_to_rename == 0 then
            vim.notify('No files selected for renaming', vim.log.levels.WARN)
            return
        end
        
        if #files_to_rename == 1 then
            local old_name = files_to_rename[1]
            local old_path = path.join({explorer_state.current_dir, old_name})
            
            vim.ui.input({
                prompt = 'Rename to: ',
                default = old_name
            }, function(new_name)
                if new_name and new_name ~= '' and new_name ~= old_name then
                    local new_path = path.join({explorer_state.current_dir, new_name})
                    local success = vim.loop.fs_rename(old_path, new_path)
                    if success then
                        vim.schedule(function()
                            M.explorer({ _internal_call = true })
                        end)
                    else
                        vim.notify('Failed to rename file', vim.log.levels.ERROR)
                    end
                end
            end)
        else
            local buf = vim.api.nvim_create_buf(false, true)
            local lines = {}
            for _, file in ipairs(files_to_rename) do
                table.insert(lines, file)
            end
            
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
            vim.api.nvim_buf_set_name(buf, 'Rename Files')
            
            vim.api.nvim_create_autocmd('BufWriteCmd', {
                buffer = buf,
                callback = function()
                    local new_names = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                    
                    if #new_names ~= #files_to_rename then
                        vim.notify('Number of lines must match number of files', vim.log.levels.ERROR)
                        return
                    end
                    
                    for i, old_name in ipairs(files_to_rename) do
                        local new_name = new_names[i]
                        if new_name and new_name ~= old_name then
                            local old_path = path.join({explorer_state.current_dir, old_name})
                            local new_path = path.join({explorer_state.current_dir, new_name})
                            local success = vim.loop.fs_rename(old_path, new_path)
                            if not success then
                                vim.notify('Failed to rename: ' .. old_name, vim.log.levels.ERROR)
                            end
                        end
                    end
                    
                    vim.api.nvim_buf_delete(buf, {force = true})
                    vim.schedule(function()
                        M.explorer({ _internal_call = true })
                    end)
                end
            })
            
            vim.api.nvim_win_set_buf(0, buf)
        end
    end
end

local function cut_files_action(opts)
    return function(selected)
        explorer_state.operation = 'cut'
        
        local files_to_process = {}
        if selected and #selected > 0 then
            for _, sel in ipairs(selected) do
                local file_info = extract_filename(sel)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_process, path.join({explorer_state.current_dir, file_info}))
                end
            end
        else
            local current_entry = opts.current_entry
            if current_entry then
                local file_info = extract_filename(current_entry)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_process, path.join({explorer_state.current_dir, file_info}))
                end
            end
        end
        
        for _, file_path in ipairs(files_to_process) do
            -- Check if file is already in cut list
            local cut_index = nil
            for i, cut_file in ipairs(explorer_state.cut_files) do
                if cut_file == file_path then
                    cut_index = i
                    break
                end
            end
            
            -- Check if file is in copy list
            local copy_index = nil
            for i, copy_file in ipairs(explorer_state.copy_files) do
                if copy_file == file_path then
                    copy_index = i
                    break
                end
            end
            
            if cut_index then
                -- File already in cut list, remove it (toggle off)
                table.remove(explorer_state.cut_files, cut_index)
            else
                -- File not in cut list, add it
                if copy_index then
                    -- Remove from copy list first
                    table.remove(explorer_state.copy_files, copy_index)
                end
                table.insert(explorer_state.cut_files, file_path)
            end
        end
        
        vim.notify('Cut ' .. #explorer_state.cut_files .. ' files', vim.log.levels.INFO)
        show_clipboard_buffer()
        
        -- Resume the picker to keep it open
        actions.resume()
    end
end

local function copy_files_action(opts)
    return function(selected)
        explorer_state.operation = 'copy'
        
        local files_to_process = {}
        if selected and #selected > 0 then
            for _, sel in ipairs(selected) do
                local file_info = extract_filename(sel)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_process, path.join({explorer_state.current_dir, file_info}))
                end
            end
        else
            local current_entry = opts.current_entry
            if current_entry then
                local file_info = extract_filename(current_entry)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_process, path.join({explorer_state.current_dir, file_info}))
                end
            end
        end
        
        for _, file_path in ipairs(files_to_process) do
            -- Check if file is already in copy list
            local copy_index = nil
            for i, copy_file in ipairs(explorer_state.copy_files) do
                if copy_file == file_path then
                    copy_index = i
                    break
                end
            end
            
            -- Check if file is in cut list
            local cut_index = nil
            for i, cut_file in ipairs(explorer_state.cut_files) do
                if cut_file == file_path then
                    cut_index = i
                    break
                end
            end
            
            if copy_index then
                -- File already in copy list, remove it (toggle off)
                table.remove(explorer_state.copy_files, copy_index)
            else
                -- File not in copy list, add it
                if cut_index then
                    -- Remove from cut list first
                    table.remove(explorer_state.cut_files, cut_index)
                end
                table.insert(explorer_state.copy_files, file_path)
            end
        end
        
        vim.notify('Copied ' .. #explorer_state.copy_files .. ' files', vim.log.levels.INFO)
        show_clipboard_buffer()
        
        -- Resume the picker to keep it open
        actions.resume()
    end
end

local function paste_files_action(opts)
    return function()
        local files_to_paste = {}
        local operation = explorer_state.operation
        
        if operation == 'cut' then
            files_to_paste = explorer_state.cut_files
        elseif operation == 'copy' then
            files_to_paste = explorer_state.copy_files
        else
            vim.notify('No files to paste', vim.log.levels.WARN)
            return
        end
        
        if #files_to_paste == 0 then
            vim.notify('No files to paste', vim.log.levels.WARN)
            return
        end
        
        local summary = {}
        table.insert(summary, 'Operation: ' .. (operation == 'cut' and 'Move' or 'Copy'))
        table.insert(summary, 'Target directory: ' .. explorer_state.current_dir)
        table.insert(summary, 'Files:')
        
        for _, file_path in ipairs(files_to_paste) do
            -- Show path relative to current working directory (same as clipboard buffer)
            local display_path = path.relative_to(file_path, vim.fn.getcwd()) or vim.fn.fnamemodify(file_path, ':t')
            table.insert(summary, '  - ' .. display_path)
        end
        
        table.insert(summary, '')
        table.insert(summary, 'Confirm? (y/n)')
        
        vim.ui.input({
            prompt = table.concat(summary, '\n') .. '\n> '
        }, function(input)
            if input and input:lower() == 'y' then
                for _, file_path in ipairs(files_to_paste) do
                    local filename = vim.fn.fnamemodify(file_path, ':t')
                    local target_path = path.join({explorer_state.current_dir, filename})
                    
                    if operation == 'cut' then
                        -- Use mv command for moving directories and files
                        local success = vim.fn.system('mv "' .. file_path .. '" "' .. target_path .. '"')
                        if vim.v.shell_error ~= 0 then
                            vim.notify('Failed to move: ' .. filename, vim.log.levels.ERROR)
                        end
                    elseif operation == 'copy' then
                        local success = vim.fn.system('cp -r "' .. file_path .. '" "' .. target_path .. '"')
                        if vim.v.shell_error ~= 0 then
                            vim.notify('Failed to copy: ' .. filename, vim.log.levels.ERROR)
                        end
                    end
                end
                
                explorer_state.cut_files = {}
                explorer_state.copy_files = {}
                explorer_state.operation = nil
                hide_clipboard_buffer()
                
                vim.schedule(function()
                    M.explorer({ _internal_call = true })
                end)
            end
        end)
    end
end

local function delete_files_action(opts)
    return function(selected)
        local files_to_delete = {}
        
        if selected and #selected > 0 then
            for _, sel in ipairs(selected) do
                local file_info = extract_filename(sel)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_delete, file_info)
                end
            end
        else
            local current_entry = opts.current_entry
            if current_entry then
                local file_info = extract_filename(current_entry)
                if file_info and file_info ~= '../' then
                    table.insert(files_to_delete, file_info)
                end
            end
        end
        
        if #files_to_delete == 0 then
            vim.notify('No files selected for deletion', vim.log.levels.WARN)
            return
        end
        
        local summary = 'Delete ' .. #files_to_delete .. ' files?\n'
        for _, file in ipairs(files_to_delete) do
            summary = summary .. '  - ' .. file .. '\n'
        end
        
        vim.ui.input({
            prompt = summary .. 'Confirm? (y/n): '
        }, function(input)
            if input and input:lower() == 'y' then
                for _, file in ipairs(files_to_delete) do
                    local file_path = path.join({explorer_state.current_dir, file})
                    local success = vim.fn.delete(file_path, 'rf')
                    if success ~= 0 then
                        vim.notify('Failed to delete: ' .. file, vim.log.levels.ERROR)
                    end
                end
                
                vim.schedule(function()
                    M.explorer({ _internal_call = true })
                end)
            end
        end)
    end
end

local function go_to_cwd_action(opts)
    return function()
        explorer_state.current_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
        vim.schedule(function()
            M.explorer({ _internal_call = true })
        end)
    end
end

function M.explorer(opts)
    opts = opts or {}
    
    -- Always default to current file directory unless explicitly specified
    local current_dir
    if opts.cwd then
        -- Use explicitly passed directory
        current_dir = opts.cwd
    elseif opts._internal_call and explorer_state.current_dir then
        -- Use stored directory only for internal calls (after operations)
        current_dir = explorer_state.current_dir
    else
        -- Default to current file directory for fresh calls
        current_dir = get_current_file_dir()
    end
    
    current_dir = vim.fn.fnamemodify(current_dir, ':p')
    explorer_state.current_dir = current_dir
    
    -- Show clipboard buffer if there are files in clipboard
    if #explorer_state.cut_files > 0 or #explorer_state.copy_files > 0 then
        show_clipboard_buffer()
    end
    
    local files = get_files_in_dir(current_dir)
    local entries = {}
    
    -- Normalize opts like files() does
    local normalized_opts = config.normalize_opts({
        cwd = current_dir,
        file_icons = true,
        color_icons = true
    }, "files")
    
    for _, file in ipairs(files) do
        -- Use make_entry.file to properly format entries with icons
        local entry = make_entry.file(file.name, normalized_opts)
        table.insert(entries, entry)
    end
    
    local fzf_opts = {
        prompt = 'Explorer> ',
        cwd = current_dir,
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'C-a:create C-r:rename C-x:cut C-y:copy C-v:paste C-g:cwd DEL:delete',
            ['--multi'] = true,
            ['--bind'] = 'tab:toggle'
        },
        previewer = 'builtin',
        winopts = {
            on_close = function()
                hide_clipboard_buffer()
            end
        },
        actions = {
            ['default'] = function(selected)
                if not selected or #selected == 0 then
                    return
                end
                
                local entry = selected[1]
                local file_info = extract_filename(entry)
                if not file_info then return end
                
                local file_path = path.join({current_dir, file_info})
                file_path = vim.fn.fnamemodify(file_path, ':p')
                local file_type = get_file_type(file_path)
                
                if file_type == 'directory' then
                    explorer_state.current_dir = file_path
                    vim.schedule(function()
                        M.explorer({ _internal_call = true })
                    end)
                else
                    vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
                    
                    local buf = vim.api.nvim_get_current_buf()
                    vim.api.nvim_create_autocmd({'BufWritePost', 'BufLeave'}, {
                        buffer = buf,
                        once = true,
                        callback = function()
                            vim.schedule(function()
                                M.explorer({ _internal_call = true })
                            end)
                        end
                    })
                end
            end,
            ['ctrl-a'] = create_file_action(opts),
            ['ctrl-r'] = rename_file_action(opts),
            ['ctrl-x'] = cut_files_action(opts),
            ['ctrl-y'] = copy_files_action(opts),
            ['ctrl-v'] = paste_files_action(opts),
            ['ctrl-g'] = go_to_cwd_action(opts),
            ['del'] = delete_files_action(opts)
        }
    }
    
    -- Use core.fzf_exec like files() does for proper icon handling
    core.fzf_exec(entries, fzf_opts)
end

return M