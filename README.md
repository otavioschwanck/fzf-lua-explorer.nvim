# FZF-Lua Explorer

A custom file explorer picker for fzf-lua with comprehensive file management capabilities.

## Features

- **Directory Navigation**: Opens in current file directory, starts with `../` for easy navigation
- **File Creation**: Create new files with `Ctrl+a`
- **File Renaming**: Rename single or multiple files with `Ctrl+r` (with conflict resolution)
- **File Operations**: Cut (`Ctrl+x`), Copy (`Ctrl+y`), and Paste (`Ctrl+v`) with conflict resolution
- **File Deletion**: Delete files with `DEL` key
- **Multi-select**: Select multiple files with `Tab`
- **Quick CWD**: Jump to current working directory with `Ctrl+g`
- **Folder Search**: Find and navigate to any folder with `Ctrl+f`
- **Conflict Resolution**: Individual conflict handling for paste and rename operations
- **Clipboard Buffer**: Visual clipboard showing cut/copied files
- **Preview**: Built-in file preview support
- **Icons**: Supports fzf-lua icons (when available)
- **Customizable Keybindings**: All shortcuts can be customized

## Installation

### Using lazy.nvim

```lua
{
  "your-username/fzf-lua-explorer",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-explorer").setup()
  end
}
```

### Using packer.nvim

```lua
use {
  "your-username/fzf-lua-explorer",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("fzf-lua-explorer").setup()
  end
}
```

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
| `Ctrl+f` | Find and navigate to folders |
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