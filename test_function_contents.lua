-- Test using function as contents (like fzf.files probably does)
local function test_function_contents()
    print("=== Testing function as contents ===")
    
    local fzf = require('fzf-lua')
    
    -- Create a function that generates entries (like files() probably does)
    local function generate_entries(cb)
        local files = {}
        local handle = vim.loop.fs_scandir('.')
        if handle then
            while true do
                local name, type = vim.loop.fs_scandir_next(handle)
                if not name then break end
                table.insert(files, name)
            end
        end
        
        -- Call the callback with each entry
        for _, file in ipairs(files) do
            cb(file)
        end
        
        -- Signal end
        cb(nil)
    end
    
    print("Testing with function contents and file_icons=true...")
    
    fzf.fzf_exec(generate_entries, {
        prompt = 'Function Contents> ',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Using function contents - should show icons!'
        },
        actions = {
            ['default'] = function(selected)
                print("Selected:", vim.inspect(selected))
            end
        }
    })
end

local function test_coroutine_contents()
    print("\n=== Testing coroutine contents ===")
    
    local fzf = require('fzf-lua')
    
    -- Another approach - using coroutine
    local function generate_entries_coro()
        local files = {}
        local handle = vim.loop.fs_scandir('.')
        if handle then
            while true do
                local name, type = vim.loop.fs_scandir_next(handle)
                if not name then break end
                table.insert(files, name)
            end
        end
        
        return coroutine.create(function()
            for _, file in ipairs(files) do
                coroutine.yield(file)
            end
        end)
    end
    
    fzf.fzf_exec(generate_entries_coro(), {
        prompt = 'Coroutine Contents> ',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--header'] = 'Using coroutine contents - testing icons'
        }
    })
end

_G.test_function_contents = test_function_contents
_G.test_coroutine_contents = test_coroutine_contents

print("=== Function Contents Test ===")
print("1. test_function_contents() - Test with callback function")
print("2. test_coroutine_contents() - Test with coroutine")

return {
    test_function_contents = test_function_contents,
    test_coroutine_contents = test_coroutine_contents
}