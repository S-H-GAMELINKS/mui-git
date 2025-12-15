## [Unreleased]

## [0.2.0] 2025-12-15

### Changed
- Use `<Leader>` prefix for plugin keymaps to avoid conflicts with Mui core keybindings
  - `q` → `<Leader>q` for closing git buffers
  - `dv` → `<Leader>d` for vertical diff split
  - `cc` → `<Leader>c` for opening commit message buffer
  - `Enter` → `<Leader>r` for showing commit diff in Log/Blame buffers

### Fixed
- Fix `handle_quit` to use `close_current_window` method

## [0.1.0] 2025-12-11

### Added
- Initial release
- Interactive git status buffer (`:Git` or `:Git status`)
- Diff buffer with syntax highlighting (`:Git diff`)
- Git log viewing (`:Git log`)
- Git blame viewing (`:Git blame`)
- Stage files (`:Git add` or `s` key)
- Unstage files (`u` key)
- Toggle stage/unstage (`-` key)
- Vertical diff split (`dv` keys)
- Close buffer (`q` key)
- Refresh status (`R` key)
- Diff highlighting:
  - Added lines in green
  - Deleted lines in red
  - Hunk headers in cyan
  - File headers in yellow (bold)
- Commit message buffer:
  - Press `cc` in status buffer to open commit message editor
  - Write commit message at top of buffer (lines starting with `#` are ignored)
  - Save with `:w` to execute commit
  - Cancel with `:q`
  - Shows current branch and staged files as reference
  - Status buffer automatically refreshes after successful commit
- Log/Blame commit navigation:
  - Press `Enter` in log buffer to view commit diff
  - Press `Enter` in blame buffer to view the commit that last modified the current line
  - Commit diff opens in vertical split with syntax highlighting
  - Uncommitted changes (`00000000`) in blame buffer are skipped
  - New buffer classes: LogBuffer, BlameBuffer, CommitShowBuffer

