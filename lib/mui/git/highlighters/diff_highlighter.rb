# frozen_string_literal: true

module Mui
  module Git
    module Highlighters
      # Highlighter for git diff output
      class DiffHighlighter < Mui::Highlighters::Base
        PRIORITY_DIFF = 50

        def highlights_for(row, line, _options = {})
          style = style_for_line(line)
          return [] unless style

          [
            Mui::Highlight.new(
              start_col: 0,
              end_col: line.length,
              style: style,
              priority: priority
            )
          ]
        end

        def priority
          PRIORITY_DIFF
        end

        private

        def style_for_line(line)
          case line
          when /^@@/
            :diff_hunk
          when /^\+\+\+/, /^---/, /^diff --git/, /^index /
            :diff_header
          when /^\+/
            :diff_add
          when /^-/
            :diff_delete
          end
        end
      end
    end
  end
end
