-- Test what format make_entry.file returns
local function test_entry_format()
    print("=== Testing make_entry.file format ===")
    
    local config = require('fzf-lua.config')
    local make_entry = require('fzf-lua.make_entry')
    
    local normalized_opts = config.normalize_opts({
        cwd = '.',
        file_icons = true,
        color_icons = true
    }, "files")
    
    local files = {"README.md", "lua/", "task.txt"}
    
    print("Entry formats:")
    for _, file in ipairs(files) do
        local entry = make_entry.file(file, normalized_opts)
        print(string.format("File: '%s' -> Entry: %s (type: %s)", file, vim.inspect(entry), type(entry)))
        
        -- Test how to extract filename
        if type(entry) == "table" then
            print("  Entry keys:", table.concat(vim.tbl_keys(entry), ", "))
            if entry.path then
                print("  Entry.path:", entry.path)
            end
            if entry.filename then
                print("  Entry.filename:", entry.filename)
            end
        elseif type(entry) == "string" then
            print("  String entry, testing patterns...")
            -- Test common patterns to extract filename
            local patterns = {
                "^.-%s+(.+)$",  -- icon + spaces + filename
                "^.-%s(.+)$",   -- icon + space + filename  
                "([^%s]+)$",    -- last non-space part
                "(.+)$"         -- entire string
            }
            for i, pattern in ipairs(patterns) do
                local match = entry:match(pattern)
                print(string.format("  Pattern %d '%s': '%s'", i, pattern, match or "no match"))
            end
        end
        print()
    end
end

_G.test_entry_format = test_entry_format
return { test_entry_format = test_entry_format }