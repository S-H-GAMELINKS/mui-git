# frozen_string_literal: true

require "open3"
require "shellwords"

module Mui
  module Git
    # Executes git commands and handles errors
    class CommandRunner
      class NotInGitRepositoryError < StandardError
        def initialize
          super("Not in a git repository")
        end
      end

      class GitCommandError < StandardError
        attr_reader :stderr, :exit_status

        def initialize(message, stderr: nil, exit_status: nil)
          super(message)
          @stderr = stderr
          @exit_status = exit_status
        end
      end

      # Check if current directory is inside a git repository
      def in_git_repository?
        _, _, status = Open3.capture3("git", "rev-parse", "--git-dir")
        status.success?
      end

      # Get git status in porcelain format
      def status
        run("status", "--porcelain")
      end

      # Get diff for a file or all files
      def diff(file_path = nil)
        if file_path
          run("diff", "--", file_path)
        else
          run("diff")
        end
      end

      # Get staged diff
      def diff_staged(file_path = nil)
        if file_path
          run("diff", "--cached", "--", file_path)
        else
          run("diff", "--cached")
        end
      end

      # Get git log
      def log(limit: 20, format: nil)
        args = ["log", "--oneline", "--decorate", "-n", limit.to_s]
        args += ["--format=#{format}"] if format
        run(*args)
      end

      # Get git blame for a file
      def blame(file_path)
        run("blame", "--", file_path)
      end

      # Stage a file
      def add(file_path)
        run("add", "--", file_path)
      end

      # Unstage a file
      def reset(file_path)
        run("reset", "HEAD", "--", file_path)
      end

      # Create a commit
      def commit(message)
        run("commit", "-m", message)
      end

      # Get current branch name
      def current_branch
        run("rev-parse", "--abbrev-ref", "HEAD").strip
      end

      # Show diff for a specific commit
      def show(commit_hash)
        run("show", "--format=fuller", commit_hash)
      end

      # Run a git command synchronously
      def run(*args)
        ensure_git_repository!

        stdout, stderr, status = Open3.capture3("git", *args)

        unless status.success?
          raise GitCommandError.new(
            "git #{args.join(" ")} failed: #{stderr.lines.first&.strip}",
            stderr: stderr,
            exit_status: status.exitstatus
          )
        end

        stdout
      end

      private

      def ensure_git_repository!
        raise NotInGitRepositoryError unless in_git_repository?
      end
    end
  end
end
