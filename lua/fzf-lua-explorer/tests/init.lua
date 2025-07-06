local explorer = require('fzf-lua-explorer.explorer')

local function create_test_structure()
    local test_dir = '/tmp/fzf_explorer_test'
    os.execute('rm -rf ' .. test_dir)
    os.execute('mkdir -p ' .. test_dir)
    os.execute('mkdir -p ' .. test_dir .. '/subdir1')
    os.execute('mkdir -p ' .. test_dir .. '/subdir2')
    
    local files = {
        test_dir .. '/file1.txt',
        test_dir .. '/file2.lua',
        test_dir .. '/subdir1/nested_file.txt',
        test_dir .. '/subdir2/another_file.py'
    }
    
    for _, file in ipairs(files) do
        local f = io.open(file, 'w')
        if f then
            f:write('Test content for ' .. file)
            f:close()
        end
    end
    
    return test_dir
end

local function test_explorer()
    local test_dir = create_test_structure()
    
    print('Test directory created at: ' .. test_dir)
    print('Test files:')
    os.execute('find ' .. test_dir .. ' -type f')
    
    print('\nTo test the explorer, run:')
    print('vim -c "cd ' .. test_dir .. '" -c "lua require(\'fzf-lua-explorer\').explorer()"')
    
    print('\nKey bindings to test:')
    print('- Enter: Navigate into directories or open files')
    print('- Ctrl+a: Create new file')
    print('- Ctrl+r: Rename file/files')
    print('- Ctrl+x: Cut file/files')
    print('- Ctrl+y: Copy file/files')
    print('- Ctrl+v: Paste files (after cut/copy)')
    print('- Ctrl+g: Go to current working directory')
    print('- Tab: Select multiple files')
    print('- DEL: Delete file/files')
    
    return test_dir
end

local function run_basic_tests()
    print('Running basic functionality tests...')
    
    local test_dir = create_test_structure()
    
    local original_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. test_dir)
    
    print('✓ Test directory structure created')
    print('✓ Changed to test directory: ' .. test_dir)
    
    local files = vim.fn.glob(test_dir .. '/*', false, true)
    print('✓ Found ' .. #files .. ' items in test directory')
    
    vim.cmd('cd ' .. original_cwd)
    print('✓ Restored original directory')
    
    print('\nBasic tests passed!')
    print('Manual testing required for full functionality.')
    print('Run: lua require("fzf-lua-explorer.tests").test_explorer()')
end

return {
    test_explorer = test_explorer,
    run_basic_tests = run_basic_tests,
    create_test_structure = create_test_structure
}