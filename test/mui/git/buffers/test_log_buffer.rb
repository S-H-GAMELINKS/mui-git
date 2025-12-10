# frozen_string_literal: true

require "test_helper"

class Mui::Git::Buffers::TestLogBuffer < Minitest::Test
  def setup
    @mock_runner = Minitest::Mock.new
  end

  def test_is_a_log_buffer
    @mock_runner.expect(:log, "abc1234 First commit\ndef5678 Second commit\n") { |limit:| limit == 20 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner)

    assert buffer.is_a?(Mui::Git::Buffers::LogBuffer)
    @mock_runner.verify
  end

  def test_parses_log_output
    @mock_runner.expect(:log, "abc1234 First commit\ndef5678 Second commit\n") { |limit:| limit == 20 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner)

    assert_equal 2, buffer.lines.size
    assert_equal "abc1234 First commit", buffer.lines[0]
    assert_equal "def5678 Second commit", buffer.lines[1]
    @mock_runner.verify
  end

  def test_commit_at_returns_hash_for_valid_row
    @mock_runner.expect(:log, "abc1234 First commit\ndef5678 Second commit\n") { |limit:| limit == 20 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner)

    assert_equal "abc1234", buffer.commit_at(0)
    assert_equal "def5678", buffer.commit_at(1)
    @mock_runner.verify
  end

  def test_commit_at_returns_nil_for_invalid_row
    @mock_runner.expect(:log, "abc1234 First commit\n") { |limit:| limit == 20 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner)

    assert_nil buffer.commit_at(5)
    @mock_runner.verify
  end

  def test_commit_at_returns_nil_for_non_matching_line
    @mock_runner.expect(:log, "No commits yet\n") { |limit:| limit == 20 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner)

    assert_nil buffer.commit_at(0)
    @mock_runner.verify
  end

  def test_displays_no_commits_when_empty
    @mock_runner.expect(:log, "") { |limit:| limit == 20 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner)

    assert_equal "(no commits)", buffer.lines[0]
    @mock_runner.verify
  end

  def test_custom_limit
    @mock_runner.expect(:log, "abc1234 First commit\n") { |limit:| limit == 10 }

    buffer = Mui::Git::Buffers::LogBuffer.new(runner: @mock_runner, limit: 10)

    assert_equal 1, buffer.lines.size
    @mock_runner.verify
  end
end
