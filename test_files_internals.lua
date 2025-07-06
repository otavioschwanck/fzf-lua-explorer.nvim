-- Test to understand how fzf.files() works internally
local function investigate_files()
    print("=== Investigating fzf.files() internals ===")
    
    local fzf = require('fzf-lua')
    
    -- Check if files uses a different function
    print("1. Checking fzf-lua config...")
    local config = require('fzf-lua.config')
    
    if config.defaults then
        print("Default file_icons:", config.defaults.file_icons)
        print("Default color_icons:", config.defaults.color_icons)
    end
    
    -- Check if there's a specific files configuration
    if config.files then
        print("Files config:", vim.inspect(config.files))
    end
    
    print("\n2. Checking fzf-lua providers...")
    local providers = require('fzf-lua.providers')
    
    if providers and providers.files then
        print("Found providers.files")
        -- Let's see what the files provider does differently
    end
    
    print("\n3. Testing with fn_transform...")
    
    -- Maybe files() uses fn_transform to add icons
    local entries = {"README.md", "lua/", "task.txt"}
    
    fzf.fzf_exec(entries, {
        prompt = 'Transform Test> ',
        file_icons = true,
        color_icons = true,
        fn_transform = function(x)
            -- Try to mimic what files() might do
            local devicons = require('nvim-web-devicons')
            local icon, hl = devicons.get_icon(x, vim.fn.fnamemodify(x, ':e'), { default = true })
            if icon then
                return string.format('%s %s', icon, x)
            end
            return x
        end,
        fzf_opts = {
            ['--header'] = 'With fn_transform - testing manual icons'
        }
    })
end

local function test_make_entry()
    print("\n=== Testing make_entry approach ===")
    
    local fzf = require('fzf-lua')
    local utils = require('fzf-lua.utils')
    
    print("4. Testing make_entry...")
    
    if utils.make_entry and utils.make_entry.file then
        print("Found utils.make_entry.file")
        
        local entries = {}
        local files = {"README.md", "lua/", "task.txt"}
        
        for _, file in ipairs(files) do
            local entry = utils.make_entry.file(file, {
                file_icons = true,
                color_icons = true
            })
            table.insert(entries, entry)
            print("Entry for", file, ":", vim.inspect(entry))
        end
        
        fzf.fzf_exec(entries, {
            prompt = 'Make Entry Test> ',
            fzf_opts = {
                ['--header'] = 'Using utils.make_entry.file'
            }
        })
    else
        print("utils.make_entry.file not found")
    end
end

local function check_files_source()
    print("\n=== Checking files() source ===")
    
    -- Let's try to call files() and see what it actually passes to fzf_exec
    local fzf = require('fzf-lua')
    
    print("5. Let's override fzf_exec temporarily to see what files() passes...")
    
    local original_fzf_exec = fzf.fzf_exec
    
    fzf.fzf_exec = function(contents, opts)
        print("fzf_exec called with:")
        print("Contents type:", type(contents))
        if type(contents) == "table" and #contents <= 5 then
            print("Contents sample:", vim.inspect(contents))
        elseif type(contents) == "function" then
            print("Contents is a function")
        else
            print("Contents:", tostring(contents))
        end
        print("Options:", vim.inspect(opts))
        
        -- Restore original and call it
        fzf.fzf_exec = original_fzf_exec
        return original_fzf_exec(contents, opts)
    end
    
    print("Calling fzf.files() to intercept its parameters...")
    fzf.files({
        cwd = '.',
        file_icons = true,
        color_icons = true
    })
end

_G.investigate_files = investigate_files
_G.test_make_entry = test_make_entry
_G.check_files_source = check_files_source

print("=== Files Investigation Functions ===")
print("1. investigate_files() - Check config and try fn_transform")
print("2. test_make_entry()   - Test utils.make_entry.file")
print("3. check_files_source() - Intercept what files() actually does")

return {
    investigate_files = investigate_files,
    test_make_entry = test_make_entry,
    check_files_source = check_files_source
}