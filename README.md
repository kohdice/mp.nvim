# mp.nvim

Markdown preview in Neovim, rendered by the external `mp` command.

`mp.nvim` is the Neovim plugin layer. It does not implement Markdown rendering
itself and does not install the `mp` command. When you open a preview, the
plugin runs `mp --width <preview-window-width> <file>` and displays the command
output in a terminal-backed scratch buffer.

## Requirements

- Neovim >= 0.12.0
- [mp](https://github.com/kohdice/markdown-preview) executable available on `$PATH`

## Installation

```lua
-- vim.pack
vim.pack.add({
  "https://github.com/kohdice/mp.nvim",
})

vim.keymap.set("n", "<leader>mp", "<cmd>Mp<cr>", {
  desc = "Markdown preview",
})

-- lazy.nvim
{
  "kohdice/mp.nvim",
  cmd = { "Mp", "MpTab", "MpRefresh", "MpClose" },
  keys = {
    {
      "<leader>mp",
      "<cmd>Mp<cr>",
      desc = "Markdown preview",
    },
  },
}
```

## Usage

Open a saved Markdown file and run:

```vim
:Mp
```

The preview uses the current window. To open the preview in a new tab instead:

```vim
:MpTab
```

Commands:

| Command      | Description                                      |
| ------------ | ------------------------------------------------ |
| `:Mp`        | Open a preview for the current Markdown buffer.  |
| `:MpTab`     | Open a preview for the current buffer in a tab.  |
| `:MpRefresh` | Re-render the active preview.                    |
| `:MpClose`   | Close the active preview and restore the source. |

Inside the preview buffer, press `q` to close the active preview.

## Behavior

- The source buffer must be saved before rendering.
- Buffers with unsaved changes are rejected so the preview matches the file on
  disk.
- The preview refreshes automatically after the source buffer is written.
- The preview refreshes after its window is resized, so `mp` receives the
  current preview width.
- Closing the preview window or wiping out the source buffer cleans up the
  active preview state.

## License

MIT
