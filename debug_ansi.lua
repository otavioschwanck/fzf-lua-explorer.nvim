-- Debug ANSI codes in make_entry.file output
local function debug_ansi()
    print("=== Debugging ANSI codes ===")
    
    local config = require('fzf-lua.config')
    local make_entry = require('fzf-lua.make_entry')
    
    local normalized_opts = config.normalize_opts({
        cwd = '.',
        file_icons = true,
        color_icons = true
    }, "files")
    
    local entry = make_entry.file("README.md", normalized_opts)
    
    print("Raw entry:", vim.inspect(entry))
    print("Raw bytes:")
    for i = 1, #entry do
        local byte = entry:byte(i)
        local char = entry:sub(i, i)
        if byte == 27 then
            print(string.format("  %d: ESC (27)", i))
        elseif byte >= 32 and byte <= 126 then
            print(string.format("  %d: '%s' (%d)", i, char, byte))
        else
            print(string.format("  %d: <%d>", i, byte))
        end
    end
    
    -- Test different ANSI removal patterns
    local patterns = {
        '\27%[[0-9;]*m',
        '\27%[[%d;]*m',
        '\27%[%d*m',
        '\27%[[^m]*m'
    }
    
    print("\nTesting ANSI removal patterns:")
    for i, pattern in ipairs(patterns) do
        local cleaned = entry:gsub(pattern, '')
        print(string.format("Pattern %d '%s': '%s'", i, pattern, cleaned))
    end
    
    -- Manual approach: find filename part
    print("\nTesting manual extraction:")
    local filename_start = nil
    for i = #entry, 1, -1 do
        local char = entry:sub(i, i)
        if char:match('[%w%./]') then
            filename_start = i
            break
        end
    end
    
    if filename_start then
        local possible_filename = entry:sub(filename_start):match('([%w%./]+)$')
        print("Possible filename:", possible_filename)
    end
end

_G.debug_ansi = debug_ansi
return { debug_ansi = debug_ansi }