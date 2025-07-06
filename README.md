# FZF-Lua Explorer

A **fast, lightweight file browser** built on top of fzf-lua, designed for **quick file operations and editing workflows**. Navigate, create, rename, cut, copy, and manage multiple files efficiently with a **persistent session clipboard** that maintains your selections even when the explorer is closed and reopened.

Perfect for developers who want a **keyboard-driven file manager** that integrates seamlessly with their Neovim workflow.

## Key Features

### 🚀 **Fast & Efficient**
- **fzf-powered**: Lightning-fast fuzzy search through files and directories
- **Keyboard-driven**: All operations accessible via customizable shortcuts
- **Instant preview**: Built-in file preview support
- **Smart navigation**: Opens in current file directory with `../` for quick parent access
- **Project-wide folder search**: Use `Ctrl+F` to instantly search and jump to any folder in your entire project tree

### 📁 **Comprehensive File Management**
- **Multi-file operations**: Select multiple files with `Tab` for batch operations
- **File creation**: Create new files with automatic directory creation
- **Smart renaming**: Rename single or multiple files with automatic conflict resolution
- **Directory merging**: Merge directories during move/rename operations
- **Safe deletion**: Confirmation prompts for destructive operations

### 📋 **Session Clipboard**
- **Persistent clipboard**: Cut/copied files remain available even after closing the explorer
- **Visual feedback**: Floating clipboard buffer shows your current selections
- **Toggle operations**: Cut/copy the same file again to remove it from clipboard
- **Mixed operations**: Mix cut and copy operations as needed

### 🔧 **Smart Conflict Resolution**
- **Individual handling**: Resolve each conflict separately (Replace/Merge/Rename/Skip/Cancel)
- **Directory merging**: Merge source directory contents into existing target directories
- **Auto-suggestions**: Automatic unique name generation for rename conflicts
- **Batch processing**: Handle multiple conflicts efficiently

### 🎨 **Customizable Interface**
- **Flexible keybindings**: Customize all shortcuts to your preference
- **Optional icons**: File and folder icons with color support (toggleable)
- **Configurable clipboard**: Customize or disable the floating clipboard buffer
- **Adaptive sizing**: Clipboard buffer resizes based on filename lengths

## Installation

### Using lazy.nvim

```lua
{
  "otavioschwanck/fzf-lua-explorer.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-explorer").setup()
  end
}
```

### Using packer.nvim

```lua
use {
  "otavioschwanck/fzf-lua-explorer.nvim",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-explorer").setup()
  end
}
```


### Demo

![Demo](https://i.imgur.com/9cFcQHc.gif)

### Manual Installation

1. Clone this repository to your Neovim plugin directory:
   ```bash
   git clone https://github.com/your-username/fzf-lua-explorer ~/.config/nvim/lua/fzf-lua-explorer
   ```

2. Add to your Neovim configuration:
   ```lua
   require("fzf-lua-explorer").setup()
   ```

## Usage

### Basic Setup

```lua
-- Default setup with <leader>e keymap and :Explorer command
require("fzf-lua-explorer").setup()

-- Custom setup
require("fzf-lua-explorer").setup({
  keymap = "<leader>fe",  -- Custom keymap (set to false to disable)
})

-- Use directly without setup
require("fzf-lua-explorer").explorer()

-- Open explorer in project root (current working directory)
require("fzf-lua-explorer").explorer({ cwd = vim.fn.getcwd() })

-- Open explorer in a specific directory
require("fzf-lua-explorer").explorer({ cwd = "/path/to/directory" })
```

### Configuration Options

```lua
require("fzf-lua-explorer").setup({
  -- Main keymap to open explorer (set to false to disable)
  keymap = "<leader>e",         -- Default: "<leader>e"
  
  -- Show file and folder icons
  show_icons = true,            -- Default: true
  
  -- Customize keybindings
  keybindings = {
    create_file = 'ctrl-n',     -- Default: 'ctrl-a'
    rename_file = 'ctrl-r',     -- Default: 'ctrl-r'
    cut_files = 'ctrl-x',       -- Default: 'ctrl-x'
    copy_files = 'ctrl-c',      -- Default: 'ctrl-y'
    paste_files = 'ctrl-v',     -- Default: 'ctrl-v'
    clean_clipboard = 'ctrl-e', -- Default: 'ctrl-e'
    go_to_cwd = 'ctrl-h',       -- Default: 'ctrl-g'
    go_to_parent = 'ctrl-b',    -- Default: 'ctrl-b'
    find_folders = 'ctrl-f',    -- Default: 'ctrl-f'
    delete_files = 'del'        -- Default: 'del'
  },
  
  -- Customize clipboard buffer
  clipboard_buffer = {
    enabled = true,             -- Show clipboard buffer
    min_width = 40,             -- Minimum width
    max_width = 80,             -- Maximum width  
    height = 10,                -- Height
    row = 2,                    -- Row position from top
    col_offset = 2,             -- Offset from right edge
    border = 'rounded'          -- Border style
  }
})
```

### Disabling Icons

```lua
-- Disable icons for better performance or compatibility
require("fzf-lua-explorer").setup({
  show_icons = false
})
```

### Disabling Clipboard Buffer

```lua
-- Disable the floating clipboard buffer
require("fzf-lua-explorer").setup({
  clipboard_buffer = {
    enabled = false
  }
})
```

### Command Usage

```bash
# Open explorer in current directory
:Explorer

# Open explorer in specific directory
:Explorer /path/to/directory
```

### Direct API Usage

```lua
-- Open in current file's directory (default behavior)
:lua require("fzf-lua-explorer").explorer()

-- Open in project root directory
:lua require("fzf-lua-explorer").explorer({ cwd = vim.fn.getcwd() })

-- Open in specific directory
:lua require("fzf-lua-explorer").explorer({ cwd = "/home/user/projects" })

-- Open with custom keybinding
vim.keymap.set('n', '<leader>fp', function()
  require("fzf-lua-explorer").explorer({ cwd = vim.fn.getcwd() })
end, { desc = 'Open explorer in project root' })
```

### Default Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Open file or navigate into directory |
| `Ctrl+a` | Create new file |
| `Ctrl+r` | Rename file(s) with conflict resolution |
| `Ctrl+x` | Cut file(s) |
| `Ctrl+y` | Copy file(s) |
| `Ctrl+v` | Paste files with conflict resolution |
| `Ctrl+e` | Clean clipboard |
| `Ctrl+g` | Go to current working directory |
| `Ctrl+b` | Go to parent directory |
| `Ctrl+f` | Search all project folders and jump to any directory instantly |
| `Tab` | Select/deselect multiple files |
| `DEL` | Delete file(s) |

*All keybindings are customizable via the `keybindings` option in setup.*

### Multi-file Operations

- Use `Tab` to select multiple files
- Operations like rename, cut, copy, and delete work on selected files
- For renaming multiple files, a buffer opens allowing you to edit all names at once

### Testing

Run the test suite:

```lua
-- Create test environment
lua require('fzf-lua-explorer.tests').test_explorer()

-- Run basic tests
lua require('fzf-lua-explorer.tests').run_basic_tests()
```

## Requirements

- fzf-lua
- Neovim with lua support
- Standard Unix tools (cp, rm, etc.) for file operations

## Project Structure

```
lua/
└── fzf-lua-explorer/
    ├── init.lua          # Main module with setup()
    ├── explorer.lua      # Core explorer functionality
    └── tests/
        └── init.lua      # Test utilities
```
