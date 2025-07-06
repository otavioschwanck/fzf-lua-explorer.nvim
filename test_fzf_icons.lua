-- Test file to understand how fzf-lua handles icons
local fzf = require('fzf-lua')

print("=== Testing fzf-lua built-in pickers ===")

-- Test 1: Regular files picker
print("\n1. Testing fzf.files() with current directory:")
print("Running: fzf.files({ cwd = '.', file_icons = true, color_icons = true })")

-- Let's see what options the files picker uses
local files_opts = {
    cwd = '.',
    file_icons = true,
    color_icons = true,
    prompt = 'Files> ',
}

print("Files picker options:", vim.inspect(files_opts))

-- Test 2: Let's examine how fzf-lua creates entries for files
print("\n2. Testing entry creation:")

-- Get some files from current directory
local files = {}
local handle = vim.loop.fs_scandir('.')
if handle then
    while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end
        if type == 'file' and name:match('%.lua$') then
            table.insert(files, name)
            if #files >= 5 then break end  -- Just get 5 files for testing
        end
    end
end

print("Found lua files:", vim.inspect(files))

-- Test 3: Let's see how fzf-lua utils work
local utils = require('fzf-lua.utils')
local path = require('fzf-lua.path')

print("\n3. Testing fzf-lua utils:")
print("utils:", vim.inspect(getmetatable(utils)))

-- Test 4: Let's try to use fzf-lua's make_entry
if utils.make_entry then
    print("\n4. Testing utils.make_entry:")
    for _, file in ipairs(files) do
        local entry = utils.make_entry.file(file, { file_icons = true, color_icons = true })
        print("File:", file, "Entry:", vim.inspect(entry))
    end
else
    print("\n4. utils.make_entry not found")
end

-- Test 5: Let's see what the files picker actually does by examining config
print("\n5. Examining fzf-lua config:")
local config = require('fzf-lua.config')
if config and config.defaults then
    print("Default file_icons:", config.defaults.file_icons)
    print("Default color_icons:", config.defaults.color_icons)
end

-- Test 6: Let's manually create a simple test picker like files
print("\n6. Creating test picker similar to files:")

local function test_picker()
    local entries = {}
    
    -- Get files in current directory
    local handle = vim.loop.fs_scandir('.')
    if handle then
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end
            table.insert(entries, name)
        end
    end
    
    local opts = {
        prompt = 'Test> ',
        file_icons = true,
        color_icons = true,
        fzf_opts = {
            ['--multi'] = true,
        },
        actions = {
            ['default'] = function(selected)
                print("Selected:", vim.inspect(selected))
                if selected and #selected > 0 then
                    print("Would open:", selected[1])
                end
            end
        }
    }
    
    print("Test picker opts:", vim.inspect(opts))
    print("Entries sample:", vim.inspect(vim.list_slice(entries, 1, 3)))
    
    fzf.fzf_exec(entries, opts)
end

-- Print instructions
print("\n=== Instructions ===")
print("1. Run: lua require('test_fzf_icons')")
print("2. Then run: test_picker() to see how basic picker works")
print("3. Compare with: require('fzf-lua').files()")

-- Export the test function
_G.test_picker = test_picker

print("\n=== Analysis Complete ===")
print("Now run 'test_picker()' to see the picker in action")
print("Then run 'require(\"fzf-lua\").files()' to compare")