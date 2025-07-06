-- Test filename extraction function
local function test_extract_filename()
    print("=== Testing filename extraction ===")
    
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
    
    local config = require('fzf-lua.config')
    local make_entry = require('fzf-lua.make_entry')
    
    local normalized_opts = config.normalize_opts({
        cwd = '.',
        file_icons = true,
        color_icons = true
    }, "files")
    
    local files = {"README.md", "lua/", "task.txt", "../"}
    
    print("Testing filename extraction:")
    for _, file in ipairs(files) do
        local entry = make_entry.file(file, normalized_opts)
        local extracted = extract_filename(entry)
        print(string.format("'%s' -> '%s'", file, extracted))
    end
end

_G.test_extract_filename = test_extract_filename
return { test_extract_filename = test_extract_filename }