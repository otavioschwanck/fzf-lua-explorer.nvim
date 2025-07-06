-- Final test for the explorer with icons
local function test_explorer()
    print("Testing fzf-lua-explorer...")
    
    -- Load the explorer module
    local ok, explorer = pcall(require, 'fzf-lua-explorer.explorer')
    if not ok then
        print("ERROR: Cannot load explorer:", explorer)
        return
    end
    
    print("✓ Explorer module loaded")
    print("✓ Starting explorer in current directory...")
    print("✓ Icons should be visible!")
    print("✓ Test key bindings:")
    print("  - Enter: Navigate/open files")
    print("  - Ctrl+a: Create file") 
    print("  - Tab: Multi-select")
    print("  - ESC: Close")
    
    -- Start the explorer
    explorer.explorer()
end

-- Export for global access
_G.test_explorer_final = test_explorer

return { test_explorer = test_explorer }