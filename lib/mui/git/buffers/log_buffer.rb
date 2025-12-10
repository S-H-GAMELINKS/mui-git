# frozen_string_literal: true

module Mui
  module Git
    module Buffers
      # Buffer for displaying git log with commit selection
      class LogBuffer < Base
        attr_reader :runner

        def initialize(runner: CommandRunner.new, limit: 20)
          super("[Git Log]")
          @runner = runner
          @limit = limit
          refresh
        end

        def refresh
          output = @runner.log(limit: @limit)
          if output.empty?
            refresh_content("(no commits)")
          else
            refresh_content(output)
          end
        end

        # Extract commit hash from current line
        # Log format: "abc1234 commit message..."
        def commit_at(row)
          line = @lines[row]
          return nil unless line

          # Match short commit hash at start of line
          match = line.match(/^([a-f0-9]{7,40})\s/)
          match&.[](1)
        end
      end
    end
  end
end
