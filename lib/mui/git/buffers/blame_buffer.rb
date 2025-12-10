# frozen_string_literal: true

module Mui
  module Git
    module Buffers
      # Buffer for displaying git blame with commit selection
      class BlameBuffer < Base
        attr_reader :runner, :file_path

        def initialize(file_path, runner: CommandRunner.new)
          super("[Git Blame: #{File.basename(file_path)}]")
          @file_path = file_path
          @runner = runner
          refresh
        end

        def refresh
          output = @runner.blame(@file_path)
          if output.empty?
            refresh_content("(no blame data)")
          else
            refresh_content(output)
          end
        end

        # Extract commit hash from current line
        # Blame format: "abc12345 (Author Name 2024-01-01 12:00:00 +0900  1) code..."
        # or for uncommitted: "00000000 (Not Committed Yet ...)"
        def commit_at(row)
          line = @lines[row]
          return nil unless line

          # Match commit hash at start of line (skip 00000000 for uncommitted)
          match = line.match(/^([a-f0-9]{7,40})\s/)
          return nil unless match

          hash = match[1]
          # Skip uncommitted changes (all zeros)
          return nil if hash.match?(/^0+$/)

          hash
        end
      end
    end
  end
end
