-- Debug test for icons in fzf-lua-explorer
local function debug_icons()
    print("=== Icon Debug Test ===")
    
    -- Test 1: Check if fzf-lua has icons working with built-in files picker
    print("\n1. Testing fzf-lua built-in files picker with icons:")
    local fzf = require('fzf-lua')
    
    print("Opening fzf.files() with icons enabled...")
    print("This should show icons if fzf-lua icon support is working")
    
    fzf.files({
        cwd = '.',
        file_icons = true,
        color_icons = true,
        prompt = 'Built-in Files> ',
        fzf_opts = {
            ['--header'] = 'Testing built-in fzf.files() with icons - ESC to close'
        }
    })
end

local function debug_our_explorer()
    print("\n=== Our Explorer Debug ===")
    
    -- Test 2: Check our explorer
    print("\n2. Testing our explorer with same icon settings:")
    local explorer = require('fzf-lua-explorer.explorer')
    
    print("Opening our explorer...")
    print("Comparing icon display with built-in files picker")
    
    explorer.explorer()
end

local function compare_entries()
    print("\n=== Entry Format Comparison ===")
    
    -- Test 3: Compare entry formats
    print("\n3. Comparing entry formats:")
    
    local files = {}
    local handle = vim.loop.fs_scandir('.')
    if handle then
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if #files < 5 then -- Get first 5 files
                table.insert(files, {name = name, type = type})
            else
                break
            end
        end
    end
    
    print("Sample files found:")
    for i, file in ipairs(files) do
        print(string.format("  %d. %s (%s)", i, file.name, file.type))
    end
    
    -- Test our entry format vs what fzf expects
    print("\nOur entries format (just filenames):")
    for i, file in ipairs(files) do
        print(string.format("  '%s'", file.name))
    end
    
    -- Test if we can manually check what fzf-lua expects
    print("\nTesting manual picker with our format...")
    
    local entries = {}
    for _, file in ipairs(files) do
        table.insert(entries, file.name)
    end
    
    local fzf = require('fzf-lua')
    fzf.fzf_exec(entries, {
        prompt = 'Manual Test> ',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Manual test with file_icons=true - ESC to close'
        },
        actions = {
            ['default'] = function(selected)
                if selected and #selected > 0 then
                    print("Selected:", selected[1])
                end
            end
        }
    })
end

-- Export functions
_G.debug_icons = debug_icons
_G.debug_our_explorer = debug_our_explorer  
_G.compare_entries = compare_entries

print("=== Icon Debug Functions Loaded ===")
print("Run these to debug:")
print("1. debug_icons()       - Test built-in fzf.files() with icons")
print("2. debug_our_explorer() - Test our explorer")
print("3. compare_entries()   - Test manual picker with our entry format")

return {
    debug_icons = debug_icons,
    debug_our_explorer = debug_our_explorer,
    compare_entries = compare_entries
}