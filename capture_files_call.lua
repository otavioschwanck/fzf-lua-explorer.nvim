-- Capture what fzf.files() actually does
local function capture_files_call()
    local fzf = require('fzf-lua')
    
    local original_fzf_exec = fzf.fzf_exec
    local captured = {}
    
    fzf.fzf_exec = function(contents, opts)
        captured.contents_type = type(contents)
        captured.opts = opts
        
        if type(contents) == "table" then
            captured.contents_sample = {}
            for i = 1, math.min(3, #contents) do
                captured.contents_sample[i] = contents[i]
            end
        elseif type(contents) == "function" then
            captured.contents_info = "function"
        else
            captured.contents_info = tostring(contents)
        end
        
        -- Save to file
        local file = io.open('fzf_files_debug.txt', 'w')
        if file then
            file:write("=== fzf.files() internals ===\n")
            file:write("Contents type: " .. captured.contents_type .. "\n")
            file:write("Options: " .. vim.inspect(captured.opts) .. "\n")
            if captured.contents_sample then
                file:write("Contents sample: " .. vim.inspect(captured.contents_sample) .. "\n")
            elseif captured.contents_info then
                file:write("Contents info: " .. captured.contents_info .. "\n")
            end
            file:close()
        end
        
        -- Restore and call
        fzf.fzf_exec = original_fzf_exec
        return original_fzf_exec(contents, opts)
    end
    
    print("Capturing fzf.files() call...")
    fzf.files({
        cwd = '.',
        file_icons = true,
        color_icons = true
    })
    
    print("Results saved to fzf_files_debug.txt")
end

_G.capture_files_call = capture_files_call
return { capture_files_call = capture_files_call }