# frozen_string_literal: true

module Mui
  module Git
    module Buffers
      # Base class for Git buffers (inherits from Mui::Buffer)
      # Provides common functionality for git-related buffers
      class Base < Mui::Buffer
        attr_accessor :pending_key

        def initialize(name)
          super(name)
          @readonly = true
          @pending_key = nil
        end

        # Update buffer content (works even for readonly buffers)
        def refresh_content(text)
          @lines = text.lines.map(&:chomp)
          @lines = [""] if @lines.empty?
          @modified = false
        end

        # Set pending key for multi-key sequences (like dv, cc)
        def set_pending(key)
          @pending_key = key
        end

        # Clear pending key
        def clear_pending
          @pending_key = nil
        end
      end
    end
  end
end
