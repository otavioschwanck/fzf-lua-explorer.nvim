-- Try to directly copy how fzf.files() works
local function test_copy_files()
    print("=== Copying fzf.files() approach ===")
    
    -- Let's try using the exact same approach as files()
    local fzf = require('fzf-lua')
    
    -- Check if we can access the files provider directly
    local providers = require('fzf-lua.providers')
    
    if providers.files then
        print("Found providers.files, let's examine it...")
        
        -- Try to call the files provider with our own options
        local opts = {
            cwd = '.',
            file_icons = true,
            color_icons = true,
            prompt = 'Direct Files Provider> ',
            fzf_opts = {
                ['--header'] = 'Using providers.files directly'
            }
        }
        
        print("Calling providers.files(opts)...")
        providers.files(opts)
    else
        print("providers.files not found")
    end
end

local function test_builtin_approach()
    print("\n=== Testing builtin approach ===")
    
    local fzf = require('fzf-lua')
    
    -- Maybe we need to use builtin instead of fzf_exec
    local opts = {
        prompt = 'Builtin Test> ',
        cwd = '.',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Testing builtin approach'
        }
    }
    
    -- Try different builtin functions if they exist
    if fzf.builtin then
        print("Found fzf.builtin")
        if fzf.builtin.files then
            print("Calling fzf.builtin.files...")
            fzf.builtin.files(opts)
        end
    else
        print("No fzf.builtin found")
    end
end

local function check_config_difference()
    print("\n=== Checking config differences ===")
    
    -- Maybe files() sets some global config that we're missing
    local config = require('fzf-lua.config')
    local fzf = require('fzf-lua')
    
    print("Current config:")
    if config.defaults then
        print("  file_icons:", config.defaults.file_icons)
        print("  color_icons:", config.defaults.color_icons)
    end
    
    -- Try setting global defaults
    if config.set_defaults then
        print("Setting global defaults...")
        config.set_defaults({
            file_icons = true,
            color_icons = true
        })
    end
    
    -- Now try our simple test again
    local entries = {"README.md", "lua/", "task.txt"}
    
    fzf.fzf_exec(entries, {
        prompt = 'After Config> ',
        fzf_opts = {
            ['--header'] = 'After setting global config'
        }
    })
end

_G.test_copy_files = test_copy_files
_G.test_builtin_approach = test_builtin_approach  
_G.check_config_difference = check_config_difference

print("=== Copy Files Test ===")
print("1. test_copy_files()      - Try providers.files directly")
print("2. test_builtin_approach() - Try builtin functions")
print("3. check_config_difference() - Check config differences")

return {
    test_copy_files = test_copy_files,
    test_builtin_approach = test_builtin_approach,
    check_config_difference = check_config_difference
}