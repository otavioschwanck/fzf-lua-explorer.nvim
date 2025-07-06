-- Find the difference between working and non-working icon pickers
local function find_difference()
    print("=== Finding the difference ===")
    
    local fzf = require('fzf-lua')
    
    -- Test 1: Minimal test that should work (like files picker)
    print("\n1. Testing minimal picker like files():")
    
    local entries = {"README.md", "lua/", "task.txt", ".claude/"}
    
    fzf.fzf_exec(entries, {
        prompt = 'Minimal Test> ',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Minimal test - should show icons'
        }
    })
end

local function test_with_cwd()
    print("\n=== Testing with cwd ===")
    
    local fzf = require('fzf-lua')
    
    -- Test 2: Test with cwd like our explorer
    local entries = {"README.md", "lua/", "task.txt", ".claude/"}
    
    fzf.fzf_exec(entries, {
        prompt = 'CWD Test> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'With cwd - should show icons'
        }
    })
end

local function test_with_previewer()
    print("\n=== Testing with previewer ===")
    
    local fzf = require('fzf-lua')
    
    -- Test 3: Test with previewer like our explorer
    local entries = {"README.md", "lua/", "task.txt", ".claude/"}
    
    fzf.fzf_exec(entries, {
        prompt = 'Previewer Test> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        previewer = 'builtin',
        fzf_opts = {
            ['--header'] = 'With previewer - should show icons'
        }
    })
end

local function test_exact_copy()
    print("\n=== Testing exact copy of our explorer ===")
    
    local fzf = require('fzf-lua')
    
    -- Test 4: Exact copy of our explorer options
    local entries = {"README.md", "lua/", "task.txt", ".claude/"}
    
    fzf.fzf_exec(entries, {
        prompt = 'Exact Copy> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Exact copy of our explorer',
            ['--multi'] = true,
            ['--bind'] = 'tab:toggle'
        },
        previewer = 'builtin',
        actions = {
            ['default'] = function(selected)
                print("Selected:", vim.inspect(selected))
            end
        }
    })
end

_G.find_difference = find_difference
_G.test_with_cwd = test_with_cwd
_G.test_with_previewer = test_with_previewer
_G.test_exact_copy = test_exact_copy

print("=== Difference Testing Functions ===")
print("1. find_difference()   - Minimal test")
print("2. test_with_cwd()     - Add cwd")
print("3. test_with_previewer() - Add previewer")
print("4. test_exact_copy()   - Exact copy of our options")

return {
    find_difference = find_difference,
    test_with_cwd = test_with_cwd,
    test_with_previewer = test_with_previewer,
    test_exact_copy = test_exact_copy
}