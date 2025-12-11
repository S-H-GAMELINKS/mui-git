# mui-git

A Git integration plugin for [Mui](https://github.com/S-H-GAMELINKS/mui) editor, inspired by vim-fugitive.

## Installation

Add to your `.muirc`:

```ruby
Mui.use "mui-git"
```

Or install via RubyGems (when published):

```bash
gem install mui-git
```

## Features

- Interactive git status buffer
- Diff viewing with syntax highlighting
- Stage/unstage files with keyboard shortcuts
- Commit message editor buffer
- Git log and blame viewing with commit diff navigation

## Commands

| Command | Description |
|---------|-------------|
| `:Git` or `:Git status` | Open git status buffer |
| `:Git diff [file]` | Open diff buffer for file (current file if omitted) |
| `:Git log [limit]` | Show commit log (default: 20 commits) |
| `:Git blame [file]` | Show git blame for file |
| `:Git add [file\|%]` | Stage file (`%` for current file) |
| `:Git commit <message>` | Create commit with message |

## Keymaps (Status Buffer)

| Key | Description |
|-----|-------------|
| `s` | Stage file under cursor |
| `u` | Unstage file under cursor |
| `-` | Toggle stage/unstage |
| `dv` | Open diff in vertical split |
| `cc` | Open commit message buffer |
| `q` | Close buffer |
| `R` | Refresh status |

## Keymaps (Log/Blame Buffer)

| Key | Description |
|-----|-------------|
| `Enter` | Show commit diff in vertical split |
| `q` | Close buffer |

In the log buffer (`:Git log`), pressing `Enter` on a commit line opens the full commit diff with syntax highlighting.

In the blame buffer (`:Git blame`), pressing `Enter` on any line shows the diff for that line's commit. Uncommitted changes (shown as `00000000`) are skipped.

## Commit Message Buffer

When you press `cc` in the status buffer, a commit message editor opens:

1. Write your commit message at the top of the buffer
2. Lines starting with `#` are comments and will be ignored
3. Save with `:w` to execute the commit
4. Close with `:q` to cancel

The buffer shows the current branch and staged files as reference.

## Diff Highlighting

Diff output is syntax highlighted:
- Added lines (`+`) are shown in green
- Deleted lines (`-`) are shown in red
- Hunk headers (`@@`) are shown in cyan
- File headers are shown in yellow (bold)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

```bash
bundle install
bundle exec rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/S-H-GAMELINKS/mui-git.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
