# frozen_string_literal: true

module Mui
  module Git
    # Main plugin class for mui-git
    # Registers commands and keymaps for git integration
    class Plugin < Mui::Plugin
      name "git"

      def setup
        register_commands
        register_keymaps
        # Debug: keymaps registered to config
        File.write("/tmp/mui-git-setup.log", "config.keymaps[:normal].keys: #{Mui.config.keymaps[:normal]&.keys}\n", mode: "a")
      end

      private

      def register_commands
        # Main :Git command
        command(:Git) do |ctx, args|
          handle_git_command(ctx, args)
        end
      end

      def register_keymaps
        # Keymaps for Git buffers
        register_status_keymaps
        register_log_blame_keymaps
      end

      def register_status_keymaps
        # Stage file
        keymap(:normal, "s") do |ctx|
          next unless status_buffer?(ctx.buffer)

          handle_stage(ctx)
          true # Indicate key was handled
        end

        # Unstage file
        keymap(:normal, "u") do |ctx|
          next unless status_buffer?(ctx.buffer)

          handle_unstage(ctx)
          true
        end

        # Toggle stage/unstage
        keymap(:normal, "-") do |ctx|
          next unless status_buffer?(ctx.buffer)

          handle_toggle(ctx)
          true
        end

        # Diff vertical split (<Leader>d)
        keymap(:normal, "<Leader>d") do |ctx|
          next unless git_buffer?(ctx.buffer)

          handle_diff_vertical(ctx)
          true
        end

        # Commit (<Leader>c)
        keymap(:normal, "<Leader>c") do |ctx|
          next unless status_buffer?(ctx.buffer)

          handle_commit(ctx)
          true
        end

        # Quit buffer
        keymap(:normal, "<Leader>q") do |ctx|
          next unless git_buffer?(ctx.buffer)

          handle_quit(ctx)
          true
        end

        # Refresh
        keymap(:normal, "R") do |ctx|
          next unless status_buffer?(ctx.buffer)

          handle_refresh(ctx)
          true
        end
      end

      def register_log_blame_keymaps
        # Enter key to show commit diff in Log/Blame buffers
        keymap(:normal, "<Leader>r") do |ctx|
          next unless log_buffer?(ctx.buffer) || blame_buffer?(ctx.buffer)

          handle_show_commit(ctx)
          true
        end
      end

      # Command handlers

      def handle_git_command(ctx, args)
        # args is a string like "log 20" or nil
        arg_parts = args.to_s.split(/\s+/)
        subcommand = arg_parts[0]&.strip || ""

        runner = CommandRunner.new

        unless runner.in_git_repository?
          ctx.set_message("Git: not in a git repository")
          return
        end

        case subcommand
        when "", "status"
          open_status_buffer(ctx, runner)
        when "diff"
          file_path = arg_parts[1] || current_file_path(ctx)
          open_diff_buffer(ctx, file_path, runner)
        when "log"
          limit = arg_parts[1]&.to_i || 20
          show_log(ctx, limit, runner)
        when "blame"
          file_path = arg_parts[1] || current_file_path(ctx)
          show_blame(ctx, file_path, runner)
        when "add"
          file_path = resolve_file_path(arg_parts[1], ctx)
          stage_file(ctx, file_path, runner)
        when "commit"
          message = arg_parts[1..].join(" ") if arg_parts.size > 1
          create_commit(ctx, message, runner)
        else
          ctx.set_message("Git: unknown command '#{subcommand}'")
        end
      rescue CommandRunner::NotInGitRepositoryError
        ctx.set_message("Git: not in a git repository")
      rescue CommandRunner::GitCommandError => e
        ctx.set_message("Git error: #{e.message}")
      end

      # Status buffer handlers

      def handle_stage(ctx)
        file = ctx.buffer.file_at(ctx.window.cursor_row)
        return unless file

        ctx.run_shell_command("git add -- #{Shellwords.escape(file.path)}",
                             on_complete: lambda { |job|
                               if job.result[:success]
                                 ctx.buffer.refresh
                                 ctx.set_message("Staged: #{file.path}")
                               else
                                 ctx.set_message("Git error: #{job.result[:stderr]&.lines&.first&.strip}")
                               end
                             })
      end

      def handle_unstage(ctx)
        file = ctx.buffer.file_at(ctx.window.cursor_row)
        return unless file

        ctx.run_shell_command("git reset HEAD -- #{Shellwords.escape(file.path)}",
                             on_complete: lambda { |job|
                               if job.result[:success]
                                 ctx.buffer.refresh
                                 ctx.set_message("Unstaged: #{file.path}")
                               else
                                 ctx.set_message("Git error: #{job.result[:stderr]&.lines&.first&.strip}")
                               end
                             })
      end

      def handle_toggle(ctx)
        file = ctx.buffer.file_at(ctx.window.cursor_row)
        return unless file

        if file.staged?
          handle_unstage(ctx)
        else
          handle_stage(ctx)
        end
      end

      def handle_diff_vertical(ctx)
        if status_buffer?(ctx.buffer)
          file = ctx.buffer.file_at(ctx.window.cursor_row)
          return unless file

          diff_buffer = Buffers::DiffBuffer.new(file.path, runner: ctx.buffer.runner, staged: file.staged?)
          ctx.editor.window_manager.split_vertical(diff_buffer)
        end
      end

      def handle_commit(ctx)
        runner = ctx.buffer.respond_to?(:runner) ? ctx.buffer.runner : CommandRunner.new
        status_buffer = ctx.buffer if status_buffer?(ctx.buffer)

        # Callback to refresh status buffer after commit
        on_commit = lambda do
          status_buffer&.refresh
        end

        commit_buffer = Buffers::CommitBuffer.new(
          runner: runner,
          editor: ctx.editor,
          on_commit: on_commit
        )
        ctx.editor.window_manager.split_horizontal(commit_buffer)
      end

      def handle_quit(ctx)
        ctx.editor.window_manager.close_current_window
      end

      def handle_refresh(ctx)
        ctx.buffer.refresh
        ctx.set_message("Git: status refreshed")
      end

      # Helper methods

      def open_status_buffer(ctx, runner)
        status_buffer = Buffers::StatusBuffer.new(runner: runner)
        ctx.editor.window_manager.split_horizontal(status_buffer)
      end

      def open_diff_buffer(ctx, file_path, runner)
        if file_path.nil? || file_path.empty?
          ctx.set_message("Git: no file specified")
          return
        end

        diff_buffer = Buffers::DiffBuffer.new(file_path, runner: runner)
        ctx.editor.window_manager.split_horizontal(diff_buffer)
      end

      def show_log(ctx, limit, runner)
        log_buffer = Buffers::LogBuffer.new(runner: runner, limit: limit)
        ctx.editor.window_manager.split_horizontal(log_buffer)
      end

      def show_blame(ctx, file_path, runner)
        if file_path.nil? || file_path.empty?
          ctx.set_message("Git: no file specified")
          return
        end

        blame_buffer = Buffers::BlameBuffer.new(file_path, runner: runner)
        ctx.editor.window_manager.split_horizontal(blame_buffer)
      end

      def handle_show_commit(ctx)
        commit_hash = ctx.buffer.commit_at(ctx.window.cursor_row)
        return ctx.set_message("Git: no commit at cursor") unless commit_hash

        runner = ctx.buffer.runner
        commit_buffer = Buffers::CommitShowBuffer.new(commit_hash, runner: runner)
        ctx.editor.window_manager.split_vertical(commit_buffer)
      rescue CommandRunner::GitCommandError => e
        ctx.set_message("Git error: #{e.message}")
      end

      def stage_file(ctx, file_path, runner)
        if file_path.nil? || file_path.empty?
          ctx.set_message("Git: no file specified")
          return
        end

        runner.add(file_path)
        ctx.set_message("Git: staged #{file_path}")
      end

      def create_commit(ctx, message, runner)
        if message.nil? || message.strip.empty?
          ctx.set_message("Git: commit message required. Usage: :Git commit <message>")
          return
        end

        output = runner.commit(message)
        # Extract commit hash from output
        if output =~ /\[.+? ([a-f0-9]+)\]/
          ctx.set_message("Git: committed [#{::Regexp.last_match(1)}]")
        else
          ctx.set_message("Git: committed")
        end
      end

      def status_buffer?(buffer)
        buffer.is_a?(Buffers::StatusBuffer)
      end

      def log_buffer?(buffer)
        buffer.is_a?(Buffers::LogBuffer)
      end

      def blame_buffer?(buffer)
        buffer.is_a?(Buffers::BlameBuffer)
      end

      def git_buffer?(buffer)
        buffer.is_a?(Buffers::Base) ||
          buffer.is_a?(Buffers::LogBuffer) ||
          buffer.is_a?(Buffers::BlameBuffer)
      end

      def current_file_path(ctx)
        path = ctx.buffer.file_path
        return nil if path.nil? || path.start_with?("[")

        path
      end

      def resolve_file_path(arg, ctx)
        return current_file_path(ctx) if arg == "%"

        arg
      end
    end
  end
end
