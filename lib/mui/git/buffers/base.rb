# frozen_string_literal: true

module Mui
  module Git
    module Buffers
      # Base class for Git buffers (inherits from Mui::Buffer)
      # Provides common functionality for git-related buffers
      class Base < Mui::Buffer
        def initialize(name)
          super(name)
          @readonly = true
        end

        # Update buffer content (works even for readonly buffers)
        def refresh_content(text)
          @lines = text.lines.map(&:chomp)
          @lines = [""] if @lines.empty?
          @modified = false
        end
      end
    end
  end
end
