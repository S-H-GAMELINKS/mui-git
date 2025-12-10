# frozen_string_literal: true

require_relative "lib/mui/git/version"

Gem::Specification.new do |spec|
  spec.name = "mui-git"
  spec.version = Mui::Git::VERSION
  spec.authors = ["S-H-GAMELINKS"]
  spec.email = ["gamelinks007@gmail.com"]

  spec.summary = "Git integration plugin for Mui editor (fugitive.vim-like)"
  spec.description = "A Git integration plugin for Mui TUI editor. Provides interactive git status buffer with staging/unstaging, diff view, and more."
  spec.homepage = "https://github.com/S-H-GAMELINKS/mui-git"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "mui", ">= 0.1.0"
end
