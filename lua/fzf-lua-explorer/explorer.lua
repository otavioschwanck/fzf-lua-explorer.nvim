local core = require('fzf-lua.core')
local make_entry = require('fzf-lua.make_entry')
local path = require('fzf-lua.path')
local actions = require('fzf-lua.actions')

local M = {}

-- Configuration storage
local config = {
  keybindings = {
    create_file = 'ctrl-a',
    rename_file = 'ctrl-r',
    cut_files = 'ctrl-x',
    copy_files = 'ctrl-y',
    paste_files = 'ctrl-v',
    clean_clipboard = 'ctrl-e',
    go_to_cwd = 'ctrl-g',
    go_to_parent = 'ctrl-b',
    find_folders = 'ctrl-f',
    delete_files = 'del'
  },
  show_icons = true,
  clipboard_buffer = {
    enabled = true,
    min_width = 40,
    max_width = 80,
    height = 10,
    row = 2,
    col_offset = 2,
    border = 'rounded'
  }
}

-- Function to set configuration from init.lua
function M.set_config(user_config)
  config = vim.tbl_deep_extend('force', config, user_config)
end

local explorer_state = {
  current_dir = nil,
  cut_files = {},
  copy_files = {},
  operation = nil,
  clipboard_win = nil,
  clipboard_buf = nil
}

-- Generate header with current keybindings
local function generate_header()
  local kb = config.keybindings
  return string.format('%s:create %s:rename %s:cut %s:copy\n%s:cwd %s:parent %s:find folder %s:delete',
    kb.create_file:upper(), kb.rename_file:upper(), kb.cut_files:upper(),
    kb.copy_files:upper(), kb.go_to_cwd:upper(), kb.go_to_parent:upper(),
    kb.find_folders:upper(), kb.delete_files:upper()
  )
end

-- Extract filename from make_entry.file formatted entry
local function extract_filename(entry)
  if type(entry) ~= "string" then
    return entry
  end

  -- Remove ANSI escape codes and extract filename
  -- Pattern: \27[...m icon \27[0m filename
  local cleaned = entry:gsub('\27%[[0-9;]*m', '') -- Remove all ANSI codes

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

-- Calculate dynamic width based on content
local function calculate_clipboard_width(lines)
  local max_length = 0
  for _, line in ipairs(lines) do
    local length = vim.fn.strdisplaywidth(line)
    if length > max_length then
      max_length = length
    end
  end

  -- Add some padding and ensure within min/max bounds
  local width = max_length + 4
  if width < config.clipboard_buffer.min_width then
    width = config.clipboard_buffer.min_width
  elseif width > config.clipboard_buffer.max_width then
    width = config.clipboard_buffer.max_width
  end

  return width
end

-- Create floating buffer to show clipboard status
local function create_clipboard_buffer(lines)
  if explorer_state.clipboard_win and vim.api.nvim_win_is_valid(explorer_state.clipboard_win) then
    return -- Already exists
  end

  lines = lines or {}

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  explorer_state.clipboard_buf = buf

  -- Buffer settings
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'fzf-lua-explorer-clipboard')

  -- Calculate dynamic width based on content
  local width = calculate_clipboard_width(lines)
  local height = config.clipboard_buffer.height
  local row = config.clipboard_buffer.row
  local col = vim.o.columns - width - config.clipboard_buffer.col_offset

  local win_config = {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
    border = config.clipboard_buffer.border,
    style = 'minimal',
    title = ' Clipboard ',
    title_pos = 'center',
    zindex = 1000 -- High z-index to stay on top
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

-- Build clipboard buffer content
local function build_clipboard_content()
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
    table.insert(lines, 'Press ' .. config.keybindings.paste_files:upper() .. ' to paste')
    table.insert(lines, 'Press ' .. config.keybindings.clean_clipboard:upper() .. ' to clean')
  else
    table.insert(lines, 'No files in clipboard')
    table.insert(lines, '')
    table.insert(lines, config.keybindings.cut_files:upper() .. ': Cut files')
    table.insert(lines, config.keybindings.copy_files:upper() .. ': Copy files')
  end

  return lines
end

-- Update clipboard buffer content
local function update_clipboard_buffer()
  if not explorer_state.clipboard_buf or not vim.api.nvim_buf_is_valid(explorer_state.clipboard_buf) then
    return
  end

  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(explorer_state.clipboard_buf, 'modifiable', true)

  local lines = build_clipboard_content()

  -- Update buffer content
  vim.api.nvim_buf_set_lines(explorer_state.clipboard_buf, 0, -1, false, lines)

  -- Set buffer as unmodifiable
  vim.api.nvim_buf_set_option(explorer_state.clipboard_buf, 'modifiable', false)

  -- Resize window if needed
  local new_width = calculate_clipboard_width(lines)
  local current_config = vim.api.nvim_win_get_config(explorer_state.clipboard_win)
  if current_config.width ~= new_width then
    current_config.width = new_width
    current_config.col = vim.o.columns - new_width - config.clipboard_buffer.col_offset
    vim.api.nvim_win_set_config(explorer_state.clipboard_win, current_config)
  end
end

-- Show clipboard buffer
local function show_clipboard_buffer()
  if not config.clipboard_buffer.enabled then
    return -- Clipboard buffer is disabled
  end

  local lines = build_clipboard_content()
  create_clipboard_buffer(lines)
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

      local full_path = path.join({ dir, name })
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
  return function(selected, _opts)
    -- Capture current search query from fzf state
    local current_query = ""
    if _opts then
      current_query = _opts.last_query or _opts._last_query or _opts.query or ""
    end
    local current_dir = explorer_state.current_dir
    local clean_dir = vim.fn.fnamemodify(current_dir, ':p')

    vim.ui.input({
      prompt = 'Create file: ',
      default = clean_dir
    }, function(input)
      if not input or input == '' then
        -- User cancelled, return to explorer
        vim.schedule(function()
          M.explorer({ _internal_call = true, query = current_query })
        end)
        return
      end

      if input and input ~= '' then
        local file_path = input

        if not vim.startswith(file_path, '/') then
          file_path = path.join({ clean_dir, file_path })
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
          -- Return to explorer even on failure
          vim.schedule(function()
            M.explorer({ _internal_call = true, query = current_query })
          end)
        end
      end
    end)
  end
end

-- Generate unique filename by adding suffix
local function generate_unique_name(filename, directory)
  local base, ext = filename:match('^(.-)(%.[^%.]*%.?)$')
  if not base then
    base = filename
    ext = ''
  end

  local counter = 1
  local new_name = filename

  while vim.fn.filereadable(path.join({ directory, new_name })) == 1 or
    vim.fn.isdirectory(path.join({ directory, new_name })) == 1 do
    new_name = base .. '_' .. counter .. ext
    counter = counter + 1
  end

  return new_name
end

local function rename_file_action(opts)
  return function(selected, _opts)
    -- Capture current search query from fzf state
    local current_query = ""
    if _opts then
      current_query = _opts.last_query or _opts._last_query or _opts.query or ""
    end

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
      local clean_old_name = old_name:gsub('/$', '') -- Remove trailing slash for path construction
      local old_path = path.join({ explorer_state.current_dir, clean_old_name })

      vim.ui.input({
        prompt = 'Rename to: ',
        default = old_name
      }, function(new_name)
        if not new_name or new_name == '' then
          -- User cancelled or entered empty name, resume picker
          actions.resume()
          return
        end

        -- Check if we're renaming a folder and ensure trailing slash consistency
        local is_folder = old_name:match('/$') ~= nil
        if is_folder and not new_name:match('/$') then
          new_name = new_name .. '/'
        elseif not is_folder and new_name:match('/$') then
          -- Remove trailing slash if renaming a file but user added one
          new_name = new_name:gsub('/$', '')
        end

        -- After normalization, check if it's the same name
        if new_name == old_name then
          vim.notify('Same name, no change needed', vim.log.levels.INFO)
          -- Resume the picker to keep it open
          actions.resume()
          return
        end

        -- Handle path construction properly for folders
        local clean_new_name = new_name:gsub('/$', '') -- Remove trailing slash for path construction
        local new_path = path.join({ explorer_state.current_dir, clean_new_name })

        -- Check if target already exists
        if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
          local is_source_dir = vim.fn.isdirectory(old_path) == 1
          local is_target_dir = vim.fn.isdirectory(new_path) == 1

          -- Different options based on whether we're dealing with directories
          local prompt_message
          local options
          if is_source_dir and is_target_dir then
            prompt_message = string.format('Directory "%s" already exists. Choose action:', new_name)
            options = '[r] Replace  [m] Merge  [n] Rename  [c] Cancel'
          else
            prompt_message = string.format('File "%s" already exists. Choose action:', new_name)
            options = '[r] Replace  [n] Rename  [c] Cancel'
          end

          vim.ui.input({
            prompt = prompt_message .. '\n' .. options .. '\n> '
          }, function(choice)
            if not choice or choice:lower() == 'c' then
              -- Cancel - resume picker
              actions.resume()
              return
            elseif choice:lower() == 'r' then
              -- Replace - remove existing and rename
              local rm_result = vim.fn.system('rm -rf "' .. new_path .. '"')
              if vim.v.shell_error ~= 0 then
                vim.notify('Failed to remove existing file: ' .. rm_result, vim.log.levels.ERROR)
                actions.resume()
                return
              end

              local success = vim.loop.fs_rename(old_path, new_path)
              if success then
                vim.schedule(function()
                  M.explorer({ _internal_call = true, query = current_query })
                end)
              else
                vim.notify('Failed to rename file', vim.log.levels.ERROR)
                actions.resume()
              end
            elseif choice:lower() == 'm' and is_source_dir and is_target_dir then
              -- Merge directories
              local merge_result = vim.fn.system('cp -r "' .. old_path .. '/." "' .. new_path .. '/"')
              if vim.v.shell_error ~= 0 then
                vim.notify('Failed to merge directories: ' .. merge_result, vim.log.levels.ERROR)
                actions.resume()
                return
              end

              -- Remove source directory after successful merge
              local rm_result = vim.fn.system('rm -rf "' .. old_path .. '"')
              if vim.v.shell_error ~= 0 then
                vim.notify('Warning: Merge succeeded but failed to remove source: ' .. rm_result, vim.log.levels.WARN)
              end

              vim.notify('Directories merged successfully', vim.log.levels.INFO)
              vim.schedule(function()
                M.explorer({ _internal_call = true, query = current_query })
              end)
            elseif choice:lower() == 'n' then
              -- Rename - suggest a new name
              local suggested_name = generate_unique_name(clean_new_name, explorer_state.current_dir)
              if is_folder then
                suggested_name = suggested_name .. '/'
              end

              vim.ui.input({
                prompt = 'Rename to: ',
                default = suggested_name
              }, function(final_name)
                if final_name and final_name ~= '' then
                  local final_clean_name = final_name:gsub('/$', '')
                  local final_path = path.join({ explorer_state.current_dir, final_clean_name })

                  local success = vim.loop.fs_rename(old_path, final_path)
                  if success then
                    vim.schedule(function()
                      M.explorer({ _internal_call = true, query = current_query })
                    end)
                  else
                    vim.notify('Failed to rename file', vim.log.levels.ERROR)
                    actions.resume()
                  end
                else
                  actions.resume()
                end
              end)
            else
              vim.notify('Invalid choice. Please choose r, m, n, or c.', vim.log.levels.WARN)
              actions.resume()
            end
          end)
        else
          -- No conflict, proceed with rename
          local success = vim.loop.fs_rename(old_path, new_path)
          if success then
            -- Refresh the explorer with preserved search query
            vim.schedule(function()
              M.explorer({ _internal_call = true, query = current_query })
            end)
          else
            vim.notify('Failed to rename file', vim.log.levels.ERROR)
            actions.resume()
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

          -- First pass: collect all operations and conflicts
          local operations = {}
          local conflicts = {}

          for i, old_name in ipairs(files_to_rename) do
            local new_name = new_names[i]
            if new_name and new_name ~= old_name then
              -- Handle trailing slash consistency for batch rename
              local is_folder = old_name:match('/$') ~= nil
              if is_folder and not new_name:match('/$') then
                new_name = new_name .. '/'
              elseif not is_folder and new_name:match('/$') then
                new_name = new_name:gsub('/$', '')
              end

              -- Skip if names are the same after normalization
              if new_name == old_name then
                goto continue
              end

              local clean_old_name = old_name:gsub('/$', '')
              local clean_new_name = new_name:gsub('/$', '')
              local old_path = path.join({ explorer_state.current_dir, clean_old_name })
              local new_path = path.join({ explorer_state.current_dir, clean_new_name })

              local op = {
                old_name = old_name,
                new_name = new_name,
                old_path = old_path,
                new_path = new_path,
                has_conflict = vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1
              }

              table.insert(operations, op)
              if op.has_conflict then
                table.insert(conflicts, op)
              end
            end
            ::continue::
          end

          -- Close the buffer first
          vim.api.nvim_buf_delete(buf, { force = true })

          -- If there are conflicts, resolve them first
          if #conflicts > 0 then
            local function resolve_rename_conflicts(conflict_index)
              if conflict_index > #conflicts then
                -- All conflicts resolved, execute all operations
                for _, op in ipairs(operations) do
                  if not op.skip then
                    if op.merge_source_remove then
                      -- This was a merge operation, just remove the source
                      local rm_result = vim.fn.system('rm -rf "' .. op.merge_source_remove .. '"')
                      if vim.v.shell_error ~= 0 then
                        vim.notify('Warning: Merge succeeded but failed to remove source: ' .. rm_result,
                          vim.log.levels.WARN)
                      end
                    else
                      -- Normal rename operation
                      local success = vim.loop.fs_rename(op.old_path, op.new_path)
                      if not success then
                        vim.notify('Failed to rename: ' .. op.old_name, vim.log.levels.ERROR)
                      end
                    end
                  end
                end

                vim.schedule(function()
                  M.explorer({ _internal_call = true })
                end)
                return
              end

              local conflict = conflicts[conflict_index]
              local is_source_dir = vim.fn.isdirectory(conflict.old_path) == 1
              local is_target_dir = vim.fn.isdirectory(conflict.new_path) == 1

              -- Different options based on whether we're dealing with directories
              local prompt_message
              local options
              if is_source_dir and is_target_dir then
                prompt_message = string.format('Directory "%s" already exists. Choose action:', conflict.new_name)
                options = '[r] Replace  [m] Merge  [s] Skip  [c] Cancel all'
              else
                prompt_message = string.format('File "%s" already exists. Choose action:', conflict.new_name)
                options = '[r] Replace  [s] Skip  [c] Cancel all'
              end

              vim.ui.input({
                prompt = prompt_message .. '\n' .. options .. '\n> '
              }, function(choice)
                if choice and choice:lower() == 'r' then
                  -- Replace - remove existing file/directory first
                  local rm_result = vim.fn.system('rm -rf "' .. conflict.new_path .. '"')
                  if vim.v.shell_error ~= 0 then
                    vim.notify('Failed to remove existing file: ' .. rm_result, vim.log.levels.ERROR)
                    conflict.skip = true
                  end
                elseif choice and choice:lower() == 'm' and is_source_dir and is_target_dir then
                  -- Merge directories
                  local merge_result = vim.fn.system('cp -r "' ..
                    conflict.old_path .. '/." "' .. conflict.new_path .. '/"')
                  if vim.v.shell_error ~= 0 then
                    vim.notify('Failed to merge directories: ' .. merge_result, vim.log.levels.ERROR)
                    conflict.skip = true
                  else
                    -- Mark for source removal after merge
                    conflict.merge_source_remove = conflict.old_path
                  end
                elseif choice and choice:lower() == 'c' then
                  -- Cancel all remaining operations
                  vim.notify('Batch rename cancelled', vim.log.levels.INFO)
                  vim.schedule(function()
                    M.explorer({ _internal_call = true })
                  end)
                  return
                else
                  -- Skip this rename (s or anything else)
                  conflict.skip = true
                end

                -- Continue with next conflict
                resolve_rename_conflicts(conflict_index + 1)
              end)
            end

            -- Start resolving conflicts
            resolve_rename_conflicts(1)
          else
            -- No conflicts, execute all operations immediately
            for _, op in ipairs(operations) do
              local success = vim.loop.fs_rename(op.old_path, op.new_path)
              if not success then
                vim.notify('Failed to rename: ' .. op.old_name, vim.log.levels.ERROR)
              end
            end

            vim.schedule(function()
              M.explorer({ _internal_call = true })
            end)
          end
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
          table.insert(files_to_process, path.join({ explorer_state.current_dir, file_info }))
        end
      end
    else
      local current_entry = opts.current_entry
      if current_entry then
        local file_info = extract_filename(current_entry)
        if file_info and file_info ~= '../' then
          table.insert(files_to_process, path.join({ explorer_state.current_dir, file_info }))
        end
      end
    end

    for _, file_path in ipairs(files_to_process) do
      -- Remove trailing slash from directories for consistent path handling
      local clean_path = file_path:gsub('/$', '')

      -- Check if file is already in cut list
      local cut_index = nil
      for i, cut_file in ipairs(explorer_state.cut_files) do
        if cut_file == clean_path then
          cut_index = i
          break
        end
      end

      -- Check if file is in copy list
      local copy_index = nil
      for i, copy_file in ipairs(explorer_state.copy_files) do
        if copy_file == clean_path then
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
        table.insert(explorer_state.cut_files, clean_path)
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
          table.insert(files_to_process, path.join({ explorer_state.current_dir, file_info }))
        end
      end
    else
      local current_entry = opts.current_entry
      if current_entry then
        local file_info = extract_filename(current_entry)
        if file_info and file_info ~= '../' then
          table.insert(files_to_process, path.join({ explorer_state.current_dir, file_info }))
        end
      end
    end

    for _, file_path in ipairs(files_to_process) do
      -- Remove trailing slash from directories for consistent path handling
      local clean_path = file_path:gsub('/$', '')

      -- Check if file is already in copy list
      local copy_index = nil
      for i, copy_file in ipairs(explorer_state.copy_files) do
        if copy_file == clean_path then
          copy_index = i
          break
        end
      end

      -- Check if file is in cut list
      local cut_index = nil
      for i, cut_file in ipairs(explorer_state.cut_files) do
        if cut_file == clean_path then
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
        table.insert(explorer_state.copy_files, clean_path)
      end
    end

    vim.notify('Copied ' .. #explorer_state.copy_files .. ' files', vim.log.levels.INFO)
    show_clipboard_buffer()

    -- Resume the picker to keep it open
    actions.resume()
  end
end


-- Execute paste operations
local function execute_paste_operations(operations, query)
  for _, op in ipairs(operations) do
    -- Check if source exists
    if vim.fn.isdirectory(op.source) == 0 and vim.fn.filereadable(op.source) == 0 then
      vim.notify('Source no longer exists: ' .. op.source, vim.log.levels.ERROR)
      goto continue
    end

    -- Check if source and target are the same
    if vim.fn.resolve(op.source) == vim.fn.resolve(op.target) then
      vim.notify('Cannot copy/move to itself: ' .. op.filename, vim.log.levels.WARN)
      goto continue
    end

    if op.operation_type == 'cut' then
      if op.merge_operation then
        -- For merge operations, merge source into target, then remove source
        local merge_result = vim.fn.system('cp -r "' .. op.source .. '/." "' .. op.target .. '/"')
        if vim.v.shell_error ~= 0 then
          vim.notify('Failed to merge directories: ' .. op.filename .. ' - ' .. merge_result, vim.log.levels.ERROR)
          goto continue
        end
        -- Remove source directory after successful merge
        local rm_result = vim.fn.system('rm -rf "' .. op.source .. '"')
        if vim.v.shell_error ~= 0 then
          vim.notify('Warning: Merge succeeded but failed to remove source: ' .. op.filename .. ' - ' .. rm_result,
            vim.log.levels.WARN)
        end
      else
        -- For move operations, remove target first if it exists, then move
        if vim.fn.isdirectory(op.target) == 1 or vim.fn.filereadable(op.target) == 1 then
          local rm_result = vim.fn.system('rm -rf "' .. op.target .. '"')
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to remove target: ' .. op.target .. ' - ' .. rm_result, vim.log.levels.ERROR)
            goto continue
          end
        end
        local mv_result = vim.fn.system('mv "' .. op.source .. '" "' .. op.target .. '"')
        if vim.v.shell_error ~= 0 then
          vim.notify('Failed to move: ' .. op.filename .. ' - ' .. mv_result, vim.log.levels.ERROR)
        end
      end
    elseif op.operation_type == 'copy' then
      if op.merge_operation then
        -- For merge operations, merge source into target
        local merge_result = vim.fn.system('cp -r "' .. op.source .. '/." "' .. op.target .. '/"')
        if vim.v.shell_error ~= 0 then
          vim.notify('Failed to merge directories: ' .. op.filename .. ' - ' .. merge_result, vim.log.levels.ERROR)
        end
      else
        -- For copy operations, remove target first if it exists, then copy
        if vim.fn.isdirectory(op.target) == 1 or vim.fn.filereadable(op.target) == 1 then
          local rm_result = vim.fn.system('rm -rf "' .. op.target .. '"')
          if vim.v.shell_error ~= 0 then
            vim.notify('Failed to remove target: ' .. op.target .. ' - ' .. rm_result, vim.log.levels.ERROR)
            goto continue
          end
        end
        local cp_result = vim.fn.system('cp -r "' .. op.source .. '" "' .. op.target .. '"')
        if vim.v.shell_error ~= 0 then
          vim.notify('Failed to copy: ' .. op.filename .. ' - ' .. cp_result, vim.log.levels.ERROR)
        end
      end
    end
    ::continue::
  end

  -- Clear clipboard and refresh
  explorer_state.cut_files = {}
  explorer_state.copy_files = {}
  explorer_state.operation = nil
  hide_clipboard_buffer()

  vim.schedule(function()
    M.explorer({ _internal_call = true, query = query or "" })
  end)
end

-- Resolve conflicts individually
local function resolve_conflicts_individually(operations, conflicts, query)
  local conflict_index = 0
  local skipped_operations = {}

  local function process_next_conflict()
    conflict_index = conflict_index + 1
    if conflict_index > #conflicts then
      -- All conflicts resolved, execute remaining operations
      local final_operations = {}
      for _, op in ipairs(operations) do
        local should_skip = false
        for _, skipped in ipairs(skipped_operations) do
          if skipped == op then
            should_skip = true
            break
          end
        end
        if not should_skip then
          table.insert(final_operations, op)
        end
      end

      if #final_operations > 0 then
        execute_paste_operations(final_operations, query)
      else
        vim.notify('All operations cancelled', vim.log.levels.INFO)
      end
      return
    end

    local conflict = conflicts[conflict_index]
    local conflict_summary = {}
    table.insert(conflict_summary, string.format('Conflict %d of %d', conflict_index, #conflicts))
    table.insert(conflict_summary, '')

    -- Check if both source and target are directories
    local is_source_dir = vim.fn.isdirectory(conflict.source) == 1
    local is_target_dir = vim.fn.isdirectory(conflict.target) == 1

    if is_source_dir and is_target_dir then
      table.insert(conflict_summary, string.format('Directory already exists: %s', conflict.filename))
      table.insert(conflict_summary, '')
      table.insert(conflict_summary, 'Choose action:')
      table.insert(conflict_summary, '[r] Replace this directory')
      table.insert(conflict_summary, '[m] Merge directories')
      table.insert(conflict_summary, '[n] Rename this directory')
      table.insert(conflict_summary, '[s] Skip this directory')
      table.insert(conflict_summary, '[c] Cancel all remaining')
    else
      table.insert(conflict_summary, string.format('File already exists: %s', conflict.filename))
      table.insert(conflict_summary, '')
      table.insert(conflict_summary, 'Choose action:')
      table.insert(conflict_summary, '[r] Replace this file')
      table.insert(conflict_summary, '[n] Rename this file')
      table.insert(conflict_summary, '[s] Skip this file')
      table.insert(conflict_summary, '[c] Cancel all remaining')
    end

    vim.ui.input({
      prompt = table.concat(conflict_summary, '\n') .. '\n> '
    }, function(choice)
      if not choice or choice:lower() == 'c' then
        -- Cancel all - keep clipboard
        vim.notify('Operation cancelled', vim.log.levels.INFO)
        return
      elseif choice:lower() == 's' then
        -- Skip this file
        table.insert(skipped_operations, conflict)
        process_next_conflict()
      elseif choice:lower() == 'r' then
        -- Replace this file - keep operation as is
        process_next_conflict()
      elseif choice:lower() == 'm' and is_source_dir and is_target_dir then
        -- Merge directories - modify operation to merge instead of replace
        conflict.merge_operation = true
        process_next_conflict()
      elseif choice:lower() == 'n' then
        -- Rename this file
        local default_name = generate_unique_name(conflict.filename, explorer_state.current_dir)
        vim.ui.input({
          prompt = string.format('Rename "%s" to: ', conflict.filename),
          default = default_name
        }, function(new_name)
          if not new_name or new_name == '' then
            -- User cancelled, skip this file
            table.insert(skipped_operations, conflict)
          else
            -- Update the operation with new target
            conflict.target = path.join({ explorer_state.current_dir, new_name })
            conflict.filename = new_name
          end
          process_next_conflict()
        end)
      else
        local valid_choices = is_source_dir and is_target_dir and 'r, m, n, s, or c' or 'r, n, s, or c'
        vim.notify('Invalid choice. Please choose ' .. valid_choices .. '.', vim.log.levels.WARN)
        process_next_conflict()
      end
    end)
  end

  -- Start conflict resolution
  process_next_conflict()
end

local function paste_files_action(opts)
  return function(selected, _opts)
    -- Capture current search query from fzf state
    local current_query = ""
    if _opts then
      current_query = _opts.last_query or _opts._last_query or _opts.query or ""
    end
    -- Check if we have any files to paste
    if #explorer_state.cut_files == 0 and #explorer_state.copy_files == 0 then
      vim.notify('No files to paste', vim.log.levels.WARN)
      return
    end

    -- Prepare operations for both cut and copy files
    local operations = {}
    local summary = {}
    table.insert(summary, 'Paste Operations:')
    table.insert(summary, 'Target directory: ' .. explorer_state.current_dir)

    -- Add cut files (move operations)
    if #explorer_state.cut_files > 0 then
      table.insert(summary, '')
      table.insert(summary, 'Move Files:')
      for _, file_path in ipairs(explorer_state.cut_files) do
        local display_path = path.relative_to(file_path, vim.fn.getcwd()) or vim.fn.fnamemodify(file_path, ':t')
        table.insert(summary, '  - ' .. display_path)
      end
    end

    -- Add copy files (copy operations)
    if #explorer_state.copy_files > 0 then
      table.insert(summary, '')
      table.insert(summary, 'Copy Files:')
      for _, file_path in ipairs(explorer_state.copy_files) do
        local display_path = path.relative_to(file_path, vim.fn.getcwd()) or vim.fn.fnamemodify(file_path, ':t')
        table.insert(summary, '  - ' .. display_path)
      end
    end

    table.insert(summary, '')
    table.insert(summary, 'Confirm? (y/n)')

    -- Check for conflicts first
    local conflicts = {}
    local operations = {}

    -- Process cut files (move operations)
    for _, file_path in ipairs(explorer_state.cut_files) do
      -- Handle folder paths properly (remove trailing slash before getting basename)
      local clean_path = file_path:gsub('/$', '')
      local filename = vim.fn.fnamemodify(clean_path, ':t')
      local target_path = path.join({ explorer_state.current_dir, filename })

      local op = {
        source = clean_path, -- Use cleaned path for source
        target = target_path,
        filename = filename,
        operation_type = 'cut',
        has_conflict = vim.fn.filereadable(target_path) == 1 or vim.fn.isdirectory(target_path) == 1
      }

      table.insert(operations, op)
      if op.has_conflict then
        table.insert(conflicts, op)
      end
    end

    -- Process copy files (copy operations)
    for _, file_path in ipairs(explorer_state.copy_files) do
      -- Handle folder paths properly (remove trailing slash before getting basename)
      local clean_path = file_path:gsub('/$', '')
      local filename = vim.fn.fnamemodify(clean_path, ':t')
      local target_path = path.join({ explorer_state.current_dir, filename })

      local op = {
        source = clean_path, -- Use cleaned path for source
        target = target_path,
        filename = filename,
        operation_type = 'copy',
        has_conflict = vim.fn.filereadable(target_path) == 1 or vim.fn.isdirectory(target_path) == 1
      }

      table.insert(operations, op)
      if op.has_conflict then
        table.insert(conflicts, op)
      end
    end

    if #conflicts > 0 then
      -- Resolve conflicts individually
      resolve_conflicts_individually(operations, conflicts, current_query)
    else
      -- No conflicts, proceed with normal confirmation
      vim.ui.input({
        prompt = table.concat(summary, '\n') .. '\n> '
      }, function(input)
        if input and input:lower() == 'y' then
          execute_paste_operations(operations, current_query)
        end
      end)
    end
  end
end

local function delete_files_action(opts)
  return function(selected, _opts)
    -- Capture current search query from fzf state
    local current_query = ""
    if _opts then
      current_query = _opts.last_query or _opts._last_query or _opts.query or ""
    end
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
          local file_path = path.join({ explorer_state.current_dir, file })
          local success = vim.fn.delete(file_path, 'rf')
          if success ~= 0 then
            vim.notify('Failed to delete: ' .. file, vim.log.levels.ERROR)
          end
        end

        vim.schedule(function()
          M.explorer({ _internal_call = true, query = current_query })
        end)
      end
    end)
  end
end

local function clean_clipboard_action(opts)
  return function()
    -- Clear clipboard
    explorer_state.cut_files = {}
    explorer_state.copy_files = {}
    explorer_state.operation = nil
    hide_clipboard_buffer()

    vim.notify('Clipboard cleared', vim.log.levels.INFO)

    -- Resume the picker to keep it open
    actions.resume()
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

local function go_to_parent_action(opts)
  return function()
    -- Remove trailing slash before getting parent directory
    local current_without_slash = explorer_state.current_dir:gsub('/$', '')
    local parent_dir = vim.fn.fnamemodify(current_without_slash, ':h')

    -- Ensure parent dir has trailing slash for consistency
    parent_dir = vim.fn.fnamemodify(parent_dir, ':p')

    -- Ensure we don't go above root directory
    if parent_dir ~= explorer_state.current_dir and parent_dir ~= '/' then
      explorer_state.current_dir = parent_dir
      vim.schedule(function()
        M.explorer({ _internal_call = true }) -- Clear query by not passing it
      end)
    else
      vim.notify('Already at root directory', vim.log.levels.INFO)
      actions.resume()
    end
  end
end

local function find_folders_action(opts)
  return function()
    local cwd = vim.fn.getcwd()

    -- Use find command to get all directories recursively
    local find_cmd = 'find "' .. cwd .. '" -type d -not -path "*/.*" 2>/dev/null'
    local find_result = vim.fn.system(find_cmd)

    if vim.v.shell_error ~= 0 then
      vim.notify('Failed to find folders', vim.log.levels.ERROR)
      return
    end

    local folders = {}
    for folder in find_result:gmatch('[^\r\n]+') do
      if folder ~= cwd then -- Skip the root directory
        -- Make paths relative to cwd for display
        local relative_path = folder:gsub('^' .. vim.pesc(cwd) .. '/?', '')
        if relative_path ~= '' then
          table.insert(folders, relative_path)
        end
      end
    end

    if #folders == 0 then
      vim.notify('No folders found', vim.log.levels.WARN)
      return
    end

    -- Sort folders alphabetically
    table.sort(folders)

    local fzf_opts = {
      prompt = 'Find Folders> ',
      fzf_opts = {
        ['--header'] = 'Select folder to open in explorer'
      },
      actions = {
        ['default'] = function(selected)
          if not selected or #selected == 0 then
            return
          end

          local folder = selected[1]
          local full_path = path.join({ cwd, folder })

          -- Check if folder still exists
          if vim.fn.isdirectory(full_path) == 0 then
            vim.notify('Folder no longer exists: ' .. folder, vim.log.levels.ERROR)
            return
          end

          -- Open explorer in selected folder
          explorer_state.current_dir = vim.fn.fnamemodify(full_path, ':p')
          vim.schedule(function()
            M.explorer({ _internal_call = true })
          end)
        end
      }
    }

    core.fzf_exec(folders, fzf_opts)
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

  -- Create entries based on icon configuration
  if config.show_icons then
    -- Try to get normalized opts, fallback if not available
    local entry_opts
    local fzf_config = require('fzf-lua.config')
    if fzf_config.normalize_opts then
      entry_opts = fzf_config.normalize_opts({
        cwd = current_dir,
        file_icons = true,
        color_icons = true
      }, "files")
    else
      -- Fallback for older fzf-lua versions
      entry_opts = {
        cwd = current_dir,
        file_icons = true,
        color_icons = true
      }
    end

    for _, file in ipairs(files) do
      -- Use make_entry.file to properly format entries with icons
      local entry = make_entry.file(file.name, entry_opts)
      table.insert(entries, entry)
    end
  else
    -- Simple entries without icons
    for _, file in ipairs(files) do
      table.insert(entries, file.name)
    end
  end

  local fzf_opts = {
    prompt = 'Explorer> ',
    cwd = current_dir,
    file_icons = config.show_icons,
    color_icons = config.show_icons,
    query = opts.query or "",
    fzf_opts = {
      ['--header'] = generate_header(),
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

        local file_path = path.join({ current_dir, file_info })
        file_path = vim.fn.fnamemodify(file_path, ':p')
        local file_type = get_file_type(file_path)

        if file_type == 'directory' then
          explorer_state.current_dir = file_path
          vim.schedule(function()
            M.explorer({ _internal_call = true })
          end)
        else
          vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
        end
      end,
      [config.keybindings.create_file] = create_file_action(opts),
      [config.keybindings.rename_file] = rename_file_action(opts),
      [config.keybindings.cut_files] = cut_files_action(opts),
      [config.keybindings.copy_files] = copy_files_action(opts),
      [config.keybindings.paste_files] = paste_files_action(opts),
      [config.keybindings.clean_clipboard] = clean_clipboard_action(opts),
      [config.keybindings.go_to_cwd] = go_to_cwd_action(opts),
      [config.keybindings.go_to_parent] = go_to_parent_action(opts),
      [config.keybindings.find_folders] = find_folders_action(opts),
      [config.keybindings.delete_files] = delete_files_action(opts)
    }
  }

  -- Use core.fzf_exec like files() does for proper icon handling
  core.fzf_exec(entries, fzf_opts)
end

return M
