# frozen_string_literal: true

require "mui"

require_relative "git/version"
require_relative "git/command_runner"
require_relative "git/buffers/base"
require_relative "git/buffers/status_buffer"
require_relative "git/buffers/diff_buffer"
require_relative "git/buffers/commit_buffer"
require_relative "git/buffers/log_buffer"
require_relative "git/buffers/blame_buffer"
require_relative "git/buffers/commit_show_buffer"
require_relative "git/plugin"

module Mui
  module Git
    class Error < StandardError; end
  end
end

# Register the plugin with Mui
Mui.plugin_manager.register(:git, Mui::Git::Plugin)
