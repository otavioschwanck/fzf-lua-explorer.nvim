-- Explore fzf-lua internal structure
local function explore_fzf_structure()
    print("=== Exploring fzf-lua structure ===")
    
    local fzf = require('fzf-lua')
    
    print("1. fzf-lua main module keys:")
    for k, v in pairs(fzf) do
        print("  " .. k .. ": " .. type(v))
    end
    
    print("\n2. Checking if files is just a wrapper...")
    if type(fzf.files) == "function" then
        -- Get the source location/info if possible
        local info = debug.getinfo(fzf.files)
        if info then
            print("files() source:", info.source)
            print("files() short_src:", info.short_src)
        end
    end
    
    print("\n3. Check if there are internal modules...")
    local modules_to_check = {
        'fzf-lua.core',
        'fzf-lua.make_entry', 
        'fzf-lua.providers.files',
        'fzf-lua.providers'
    }
    
    for _, mod in ipairs(modules_to_check) do
        local ok, module = pcall(require, mod)
        if ok then
            print("Found module:", mod)
            if type(module) == "table" then
                print("  Keys:", table.concat(vim.tbl_keys(module), ", "))
            end
        else
            print("Module not found:", mod)
        end
    end
    
    print("\n4. Testing if the issue is with our entries...")
    -- Maybe our entries need to be full paths?
    local entries = {}
    local cwd = vim.fn.getcwd()
    
    local handle = vim.loop.fs_scandir('.')
    if handle then
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if #entries < 5 then
                -- Try full path
                table.insert(entries, cwd .. '/' .. name)
            else
                break
            end
        end
    end
    
    print("Testing with full paths:")
    for _, entry in ipairs(entries) do
        print("  " .. entry)
    end
    
    fzf.fzf_exec(entries, {
        prompt = 'Full Paths> ',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Testing with full paths'
        }
    })
end

local function test_direct_copy()
    print("\n=== Testing direct copy of files() call ===")
    
    local fzf = require('fzf-lua')
    
    -- Let's try to call files() but override just the prompt to see if that breaks icons
    fzf.files({
        prompt = 'Custom Prompt> ',  -- Only change the prompt
        cwd = '.',
        file_icons = true,
        color_icons = true
    })
end

_G.explore_fzf_structure = explore_fzf_structure
_G.test_direct_copy = test_direct_copy

print("=== Structure Explorer ===")
print("1. explore_fzf_structure() - Explore internal structure")
print("2. test_direct_copy()      - Test files() with custom prompt")

return {
    explore_fzf_structure = explore_fzf_structure,
    test_direct_copy = test_direct_copy
}