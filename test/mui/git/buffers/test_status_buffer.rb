# frozen_string_literal: true

require "test_helper"

class Mui::Git::Buffers::TestStatusBuffer < Minitest::Test
  def setup
    @mock_runner = Minitest::Mock.new
  end

  def test_file_entry_staged_returns_true_for_staged_file
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: "A",
      work_tree_status: " ",
      path: "test.txt"
    )
    assert entry.staged?
  end

  def test_file_entry_staged_returns_false_for_unstaged_file
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: " ",
      work_tree_status: "M",
      path: "test.txt"
    )
    refute entry.staged?
  end

  def test_file_entry_unstaged_returns_true_for_modified_file
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: " ",
      work_tree_status: "M",
      path: "test.txt"
    )
    assert entry.unstaged?
  end

  def test_file_entry_untracked_returns_true_for_untracked_file
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: "?",
      work_tree_status: "?",
      path: "test.txt"
    )
    assert entry.untracked?
  end

  def test_file_entry_status_display_for_untracked
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: "?",
      work_tree_status: "?",
      path: "test.txt"
    )
    assert_equal "??", entry.status_display
  end

  def test_file_entry_status_display_for_staged
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: "A",
      work_tree_status: " ",
      path: "test.txt"
    )
    assert_equal "A ", entry.status_display
  end

  def test_file_entry_status_display_for_unstaged
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: " ",
      work_tree_status: "M",
      path: "test.txt"
    )
    assert_equal " M", entry.status_display
  end

  def test_file_entry_status_display_for_staged_and_unstaged
    entry = Mui::Git::Buffers::StatusBuffer::FileEntry.new(
      index_status: "M",
      work_tree_status: "M",
      path: "test.txt"
    )
    assert_equal "MM", entry.status_display
  end

  def test_parses_status_output
    @mock_runner.expect(:status, "A  staged.txt\n M modified.txt\n?? untracked.txt\n")

    buffer = Mui::Git::Buffers::StatusBuffer.new(runner: @mock_runner)

    assert_equal 3, buffer.files.size
    assert_equal "staged.txt", buffer.files[0].path
    assert_equal "modified.txt", buffer.files[1].path
    assert_equal "untracked.txt", buffer.files[2].path

    @mock_runner.verify
  end

  def test_file_at_returns_staged_file
    @mock_runner.expect(:status, "A  staged.txt\n")

    buffer = Mui::Git::Buffers::StatusBuffer.new(runner: @mock_runner)

    # Row 0 is "Staged:" header, row 1 is the file
    file = buffer.file_at(1)
    assert_equal "staged.txt", file.path

    @mock_runner.verify
  end

  def test_file_at_returns_unstaged_file
    @mock_runner.expect(:status, " M modified.txt\n")

    buffer = Mui::Git::Buffers::StatusBuffer.new(runner: @mock_runner)

    # Row 0 is "Unstaged:" header (no staged files), row 1 is the file
    file = buffer.file_at(1)
    assert_equal "modified.txt", file.path

    @mock_runner.verify
  end

  def test_file_at_returns_nil_for_header_row
    @mock_runner.expect(:status, "A  staged.txt\n")

    buffer = Mui::Git::Buffers::StatusBuffer.new(runner: @mock_runner)

    # Row 0 is "Staged:" header
    file = buffer.file_at(0)
    assert_nil file

    @mock_runner.verify
  end

  def test_displays_working_tree_clean_when_no_changes
    @mock_runner.expect(:status, "")

    buffer = Mui::Git::Buffers::StatusBuffer.new(runner: @mock_runner)

    assert_match(/Working tree clean/, buffer.lines.join("\n"))

    @mock_runner.verify
  end

  def test_displays_help_line
    @mock_runner.expect(:status, "")

    buffer = Mui::Git::Buffers::StatusBuffer.new(runner: @mock_runner)

    assert_match(/Press: s=stage/, buffer.lines.join("\n"))

    @mock_runner.verify
  end
end
