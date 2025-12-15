# frozen_string_literal: true

module Mui
  module Git
    module Buffers
      # Interactive git status buffer
      # Displays staged/unstaged files and allows staging/unstaging
      class StatusBuffer < Base
        # Represents a file in git status
        FileEntry = Struct.new(:index_status, :work_tree_status, :path, keyword_init: true) do
          def staged?
            index_status != " " && index_status != "?"
          end

          def unstaged?
            work_tree_status != " "
          end

          def untracked?
            index_status == "?" && work_tree_status == "?"
          end

          def status_display
            case
            when untracked? then "??"
            when staged? && unstaged? then "#{index_status}#{work_tree_status}"
            when staged? then "#{index_status} "
            when unstaged? then " #{work_tree_status}"
            else "  "
            end
          end
        end

        attr_reader :files, :runner

        def initialize(runner: CommandRunner.new)
          super("[Git Status]")
          @runner = runner
          @files = []
          @staged_files = []
          @unstaged_files = []
          refresh
        end

        # Refresh git status
        def refresh
          output = @runner.status
          @files = parse_status(output)
          @staged_files = @files.select(&:staged?)
          @unstaged_files = @files.select { |f| f.unstaged? || f.untracked? }
          refresh_content(format_display)
        end

        # Get file at cursor position
        def file_at(row)
          # Account for header lines
          # Line 0: "Staged:" header (or "Unstaged:" if no staged files)
          # Lines 1..staged_count: staged files
          # Line staged_count+1: empty line (if both sections exist)
          # Line staged_count+2: "Unstaged:" header
          # Lines staged_count+3..end: unstaged files

          staged_start_row = 1
          staged_end_row = staged_start_row + @staged_files.size - 1

          unstaged_header_row = @staged_files.empty? ? 0 : staged_end_row + 2
          unstaged_start_row = unstaged_header_row + 1

          if @staged_files.any? && row >= staged_start_row && row <= staged_end_row
            @staged_files[row - staged_start_row]
          elsif @unstaged_files.any? && row >= unstaged_start_row
            index = row - unstaged_start_row
            @unstaged_files[index] if index < @unstaged_files.size
          end
        end

        private

        def parse_status(output)
          output.lines.map do |line|
            next if line.strip.empty?

            index_status = line[0]
            work_tree_status = line[1]
            path = line[3..].strip

            FileEntry.new(
              index_status: index_status,
              work_tree_status: work_tree_status,
              path: path
            )
          end.compact
        end

        def format_display
          lines = []

          if @staged_files.any?
            lines << "Staged:"
            @staged_files.each do |file|
              lines << "  #{file.status_display} #{file.path}"
            end
          end

          if @staged_files.any? && @unstaged_files.any?
            lines << ""
          end

          if @unstaged_files.any?
            lines << "Unstaged:"
            @unstaged_files.each do |file|
              lines << "  #{file.status_display} #{file.path}"
            end
          end

          if lines.empty?
            lines << "Working tree clean"
          end

          lines << ""
          lines << "Press: s=stage, u=unstage, -=toggle, \\d=diff, \\c=commit, \\q=quit, R=refresh"

          lines.join("\n")
        end
      end
    end
  end
end
