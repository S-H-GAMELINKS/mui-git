# frozen_string_literal: true

module Mui
  module Git
    module Buffers
      # Buffer for editing git commit message
      # When saved, executes git commit with the message
      class CommitBuffer < Mui::Buffer
        attr_reader :runner, :editor, :on_commit

        COMMIT_MSG_TEMPLATE = <<~MSG

          # Please enter the commit message for your changes.
          # Lines starting with '#' will be ignored.
          #
          # On branch: %<branch>s
          #
          # Changes to be committed:
          %<staged>s
        MSG

        def initialize(runner: CommandRunner.new, editor: nil, on_commit: nil)
          super("[Git Commit]")
          @runner = runner
          @editor = editor
          @on_commit = on_commit
          @readonly = false
          setup_template
        end

        # Override save to execute git commit instead of writing to file
        def save(_path = nil)
          message = extract_message
          if message.empty?
            @editor&.message = "Git: empty commit message, aborting"
            return
          end

          begin
            output = @runner.commit(message)
            if output =~ /\[.+? ([a-f0-9]+)\]/
              @editor&.message = "Git: committed [#{::Regexp.last_match(1)}]"
            else
              @editor&.message = "Git: committed"
            end
            @modified = false
            @on_commit&.call
            close_buffer
          rescue CommandRunner::GitCommandError => e
            @editor&.message = "Git error: #{e.message}"
          end
        end

        private

        def setup_template
          branch = @runner.current_branch rescue "unknown"
          staged = format_staged_files

          template = format(COMMIT_MSG_TEMPLATE, branch: branch, staged: staged)
          @lines = template.lines.map(&:chomp)
          @lines = [""] if @lines.empty?
          @modified = false
        end

        def format_staged_files
          output = @runner.status
          staged_lines = output.lines.select do |line|
            index_status = line[0]
            index_status != " " && index_status != "?"
          end

          if staged_lines.empty?
            "#   (no staged changes)"
          else
            staged_lines.map { |line| "#   #{line.strip}" }.join("\n")
          end
        end

        def extract_message
          # Filter out comment lines and join
          message_lines = @lines.reject { |line| line.start_with?("#") }
          # Remove leading/trailing blank lines
          message_lines.shift while message_lines.first&.strip&.empty?
          message_lines.pop while message_lines.last&.strip&.empty?
          message_lines.join("\n").strip
        end

        def close_buffer
          return unless @editor

          window_manager = @editor.tab_manager.current_tab.window_manager
          current_window = window_manager.active_window
          window_manager.close_current_window if current_window&.buffer == self
        end
      end
    end
  end
end
