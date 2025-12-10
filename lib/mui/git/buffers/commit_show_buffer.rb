# frozen_string_literal: true

require_relative "../highlighters/diff_highlighter"

module Mui
  module Git
    module Buffers
      # Buffer for displaying a specific commit's diff
      class CommitShowBuffer < Base
        attr_reader :runner, :commit_hash

        def initialize(commit_hash, runner: CommandRunner.new)
          super("[Git Commit: #{commit_hash[0, 7]}]")
          @commit_hash = commit_hash
          @runner = runner
          refresh
        end

        def refresh
          output = @runner.show(@commit_hash)
          if output.empty?
            refresh_content("(no commit data)")
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
