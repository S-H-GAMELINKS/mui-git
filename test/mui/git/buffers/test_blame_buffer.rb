# frozen_string_literal: true

require "test_helper"

class Mui::Git::Buffers::TestBlameBuffer < Minitest::Test
  def setup
    @mock_runner = Minitest::Mock.new
  end

  def test_is_a_blame_buffer
    @mock_runner.expect(:blame, "abc1234 (Author 2024-01-01 12:00:00 +0900 1) code\n", ["test.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("test.rb", runner: @mock_runner)

    assert buffer.is_a?(Mui::Git::Buffers::BlameBuffer)
    @mock_runner.verify
  end

  def test_parses_blame_output
    blame_output = <<~BLAME
      abc1234 (Author 2024-01-01 12:00:00 +0900 1) line 1
      def5678 (Author 2024-01-02 12:00:00 +0900 2) line 2
    BLAME
    @mock_runner.expect(:blame, blame_output, ["test.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("test.rb", runner: @mock_runner)

    assert_equal 2, buffer.lines.size
    @mock_runner.verify
  end

  def test_commit_at_returns_hash_for_valid_row
    blame_output = <<~BLAME
      abc1234 (Author 2024-01-01 12:00:00 +0900 1) line 1
      def5678 (Author 2024-01-02 12:00:00 +0900 2) line 2
    BLAME
    @mock_runner.expect(:blame, blame_output, ["test.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("test.rb", runner: @mock_runner)

    assert_equal "abc1234", buffer.commit_at(0)
    assert_equal "def5678", buffer.commit_at(1)
    @mock_runner.verify
  end

  def test_commit_at_returns_nil_for_uncommitted_changes
    blame_output = "00000000 (Not Committed Yet 2024-01-01 12:00:00 +0900 1) new line\n"
    @mock_runner.expect(:blame, blame_output, ["test.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("test.rb", runner: @mock_runner)

    assert_nil buffer.commit_at(0)
    @mock_runner.verify
  end

  def test_commit_at_returns_nil_for_invalid_row
    @mock_runner.expect(:blame, "abc1234 (Author 2024-01-01 12:00:00 +0900 1) code\n", ["test.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("test.rb", runner: @mock_runner)

    assert_nil buffer.commit_at(5)
    @mock_runner.verify
  end

  def test_displays_no_blame_data_when_empty
    @mock_runner.expect(:blame, "", ["test.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("test.rb", runner: @mock_runner)

    assert_equal "(no blame data)", buffer.lines[0]
    @mock_runner.verify
  end

  def test_stores_file_path
    @mock_runner.expect(:blame, "abc1234 (Author 2024-01-01 12:00:00 +0900 1) code\n", ["path/to/file.rb"])

    buffer = Mui::Git::Buffers::BlameBuffer.new("path/to/file.rb", runner: @mock_runner)

    assert_equal "path/to/file.rb", buffer.file_path
    @mock_runner.verify
  end
end
