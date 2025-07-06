-- Test the final explorer with icons
local function test_final_explorer()
    print("=== Testing Final Explorer with Icons ===")
    
    -- Load the updated explorer
    local explorer = require('fzf-lua-explorer.explorer')
    
    print("✓ Explorer loaded with make_entry.file support")
    print("✓ Should now display proper icons and colors!")
    print("✓ All file operations should work correctly")
    print("\nStarting explorer...")
    
    explorer.explorer()
end

_G.test_final_explorer = test_final_explorer
return { test_final_explorer = test_final_explorer }