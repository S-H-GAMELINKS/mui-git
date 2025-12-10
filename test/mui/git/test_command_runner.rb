# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class Mui::Git::TestCommandRunner < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Initialize git repository
    system("git init --quiet")
    system("git config user.email 'test@example.com'")
    system("git config user.name 'Test User'")
    system("git config commit.gpgsign false")

    @runner = Mui::Git::CommandRunner.new
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_in_git_repository_returns_true_in_git_repo
    assert @runner.in_git_repository?
  end

  def test_in_git_repository_returns_false_outside_git_repo
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        refute @runner.in_git_repository?
      end
    end
  end

  def test_status_returns_empty_for_clean_repo
    # Create and commit a file first
    File.write("test.txt", "content")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")

    assert_equal "", @runner.status
  end

  def test_status_returns_untracked_files
    File.write("untracked.txt", "content")

    output = @runner.status
    assert_match(/\?\? untracked\.txt/, output)
  end

  def test_status_returns_modified_files
    File.write("test.txt", "content")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")
    File.write("test.txt", "modified content")

    output = @runner.status
    assert_match(/ M test\.txt/, output)
  end

  def test_status_returns_staged_files
    File.write("test.txt", "content")
    system("git add test.txt")

    output = @runner.status
    assert_match(/A  test\.txt/, output)
  end

  def test_diff_returns_empty_for_no_changes
    File.write("test.txt", "content")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")

    assert_equal "", @runner.diff
  end

  def test_diff_returns_changes
    File.write("test.txt", "content\n")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")
    File.write("test.txt", "modified content\n")

    output = @runner.diff("test.txt")
    assert_match(/-content/, output)
    assert_match(/\+modified content/, output)
  end

  def test_diff_staged_returns_staged_changes
    File.write("test.txt", "content\n")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")
    File.write("test.txt", "modified content\n")
    system("git add test.txt")

    output = @runner.diff_staged("test.txt")
    assert_match(/-content/, output)
    assert_match(/\+modified content/, output)
  end

  def test_add_stages_file
    File.write("test.txt", "content")
    @runner.add("test.txt")

    output = @runner.status
    assert_match(/A  test\.txt/, output)
  end

  def test_reset_unstages_file
    File.write("test.txt", "content")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")
    File.write("test.txt", "modified")
    system("git add test.txt")

    @runner.reset("test.txt")

    output = @runner.status
    assert_match(/ M test\.txt/, output)
  end

  def test_commit_creates_commit
    File.write("test.txt", "content")
    system("git add test.txt")

    output = @runner.commit("Test commit")
    assert_match(/Test commit/, output)
  end

  def test_current_branch_returns_branch_name
    File.write("test.txt", "content")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")

    # Default branch might be main or master depending on git config
    branch = @runner.current_branch
    assert_includes %w[main master], branch
  end

  def test_log_returns_commits
    File.write("test.txt", "content")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")

    output = @runner.log(limit: 10)
    assert_match(/Initial commit/, output)
  end

  def test_blame_returns_blame_output
    File.write("test.txt", "content\n")
    system("git add test.txt")
    system("git commit -m 'Initial commit' --quiet")

    output = @runner.blame("test.txt")
    assert_match(/content/, output)
  end

  def test_raises_not_in_git_repository_error_outside_repo
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        runner = Mui::Git::CommandRunner.new
        assert_raises(Mui::Git::CommandRunner::NotInGitRepositoryError) do
          runner.status
        end
      end
    end
  end

  def test_raises_git_command_error_on_invalid_command
    assert_raises(Mui::Git::CommandRunner::GitCommandError) do
      @runner.run("invalid-command")
    end
  end
end
