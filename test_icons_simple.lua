-- Simple test to check if icons work
local M = {}

local function test_current_dir()
    print("Testing fzf-lua-explorer in current directory...")
    
    -- Test if we can load the module
    local ok, explorer = pcall(require, 'fzf-lua-explorer.explorer')
    if not ok then
        print("ERROR: Cannot load fzf-lua-explorer.explorer:", explorer)
        return false
    end
    
    print("✓ Module loaded successfully")
    
    -- Test if we can load fzf-lua
    local ok_fzf, fzf = pcall(require, 'fzf-lua')
    if not ok_fzf then
        print("ERROR: Cannot load fzf-lua:", fzf)
        return false
    end
    
    print("✓ fzf-lua loaded successfully")
    
    -- Test nvim-web-devicons
    local ok_icons, devicons = pcall(require, 'nvim-web-devicons')
    if ok_icons then
        print("✓ nvim-web-devicons available")
        local icon, hl = devicons.get_icon('test.lua', 'lua', { default = true })
        print("  Lua file icon:", icon, "highlight:", hl)
    else
        print("! nvim-web-devicons not available:", devicons)
    end
    
    -- Test basic functionality
    print("\n--- Files in current directory ---")
    local handle = vim.loop.fs_scandir('.')
    if handle then
        local count = 0
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end
            count = count + 1
            if count <= 5 then  -- Show first 5 files
                print(string.format("  %s (%s)", name, type))
            end
        end
        print(string.format("Total files/dirs: %d", count))
    end
    
    return true
end

M.test_current_dir = test_current_dir

return M