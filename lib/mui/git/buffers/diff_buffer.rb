# frozen_string_literal: true

require_relative "../highlighters/diff_highlighter"

module Mui
  module Git
    module Buffers
      # Buffer for displaying git diff
      class DiffBuffer < Base
        attr_reader :file_path, :runner

        def initialize(file_path, runner: CommandRunner.new, staged: false)
          super("[Git Diff: #{File.basename(file_path)}]")
          @file_path = file_path
          @runner = runner
          @staged = staged
          refresh
        end

        # Refresh diff content
        def refresh
          output = if @staged
                     @runner.diff_staged(@file_path)
                   else
                     @runner.diff(@file_path)
                   end

          if output.empty?
            refresh_content("(no changes)")
          else
            refresh_content(output)
          end
        end

        # Provide diff highlighter for this buffer
        def custom_highlighters(color_scheme)
          [Highlighters::DiffHighlighter.new(color_scheme)]
        end
      end
    end
  end
end
