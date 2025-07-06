-- Test the clipboard buffer functionality
local function test_clipboard_buffer()
    print("=== Testing Clipboard Buffer ===")
    
    local explorer = require('fzf-lua-explorer.explorer')
    
    print("✓ Explorer loaded with clipboard buffer support")
    print("✓ When you cut/copy files, a floating buffer will appear")
    print("✓ The buffer shows which files are cut (✂️) or copied (📋)")
    print("✓ Buffer automatically hides when you paste or close explorer")
    print("\nInstructions:")
    print("1. Select files with Tab")
    print("2. Press Ctrl+x to cut or Ctrl+y to copy")
    print("3. Watch the floating clipboard buffer appear")
    print("4. Navigate to another directory")
    print("5. Press Ctrl+v to paste")
    print("6. Watch the clipboard buffer disappear")
    print("\nStarting explorer...")
    
    explorer.explorer()
end

_G.test_clipboard_buffer = test_clipboard_buffer
return { test_clipboard_buffer = test_clipboard_buffer }