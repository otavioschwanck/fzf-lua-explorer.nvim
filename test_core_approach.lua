-- Test using core.fzf_exec and mt_cmd_wrapper like files() does
local function test_core_approach()
    print("=== Testing core approach ===")
    
    local core = require('fzf-lua.core')
    local config = require('fzf-lua.config')
    
    -- Test 1: Use core.fzf_exec instead of fzf.fzf_exec
    print("1. Testing core.fzf_exec with static entries...")
    
    local entries = {"README.md", "lua/", "task.txt"}
    
    local opts = {
        prompt = 'Core Static> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Using core.fzf_exec with static entries'
        }
    }
    
    -- Normalize opts like files() does
    opts = config.normalize_opts(opts, "files")
    
    core.fzf_exec(entries, opts)
end

local function test_mt_cmd_wrapper()
    print("\n=== Testing mt_cmd_wrapper approach ===")
    
    local core = require('fzf-lua.core')
    local config = require('fzf-lua.config')
    
    -- Test 2: Try to use mt_cmd_wrapper like files() does
    print("2. Testing with mt_cmd_wrapper...")
    
    local opts = {
        prompt = 'Core CMD> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        cmd = 'find . -maxdepth 1 -type f -o -type d | head -10',  -- Simple command to list files
        fzf_opts = {
            ['--header'] = 'Using mt_cmd_wrapper like files()'
        }
    }
    
    -- Normalize opts like files() does
    opts = config.normalize_opts(opts, "files")
    
    -- Use mt_cmd_wrapper like files() does
    local contents = core.mt_cmd_wrapper(opts)
    
    -- Set headers like files() does
    opts = core.set_header(opts, opts.headers or { "actions", "cwd" })
    
    -- Use core.fzf_exec like files() does
    core.fzf_exec(contents, opts)
end

local function test_make_entry_file()
    print("\n=== Testing make_entry.file approach ===")
    
    local core = require('fzf-lua.core')
    local config = require('fzf-lua.config')
    local make_entry = require('fzf-lua.make_entry')
    
    print("3. Testing with make_entry.file...")
    
    -- Create entries using make_entry.file like files() might do
    local entries = {}
    local files = {"README.md", "lua/", "task.txt"}
    
    local opts = {
        prompt = 'Make Entry> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Using make_entry.file'
        }
    }
    
    opts = config.normalize_opts(opts, "files")
    
    for _, file in ipairs(files) do
        local entry = make_entry.file(file, opts)
        table.insert(entries, entry)
        print("Entry for", file, ":", vim.inspect(entry))
    end
    
    core.fzf_exec(entries, opts)
end

_G.test_core_approach = test_core_approach
_G.test_mt_cmd_wrapper = test_mt_cmd_wrapper
_G.test_make_entry_file = test_make_entry_file

print("=== Core Approach Tests ===")
print("1. test_core_approach()  - Use core.fzf_exec")
print("2. test_mt_cmd_wrapper() - Use mt_cmd_wrapper like files()")
print("3. test_make_entry_file() - Use make_entry.file")

return {
    test_core_approach = test_core_approach,
    test_mt_cmd_wrapper = test_mt_cmd_wrapper,
    test_make_entry_file = test_make_entry_file
}