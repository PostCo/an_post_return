# frozen_string_literal: true

require_relative "lib/an_post_return/version"

Gem::Specification.new do |spec|
  spec.name = "an_post_return"
  spec.version = AnPostReturn::VERSION
  spec.authors = ["Andy Chong"]
  spec.email = ["andygg1996personal@gmail.com"]

  spec.summary = "Ruby wrapper for An Post's API services"
  spec.description =
    "A Ruby gem that provides a simple interface to interact with An Post's API services, specifically for return label creation and tracking information retrieval."
  spec.homepage = "https://github.com/PostCo/an_post_return"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/PostCo/an_post_return"
  spec.metadata["changelog_uri"] = "https://github.com/PostCo/an_post_return/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files =
    IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
      ls
        .readlines("\x0", chomp: true)
        .reject { |f| (f == gemspec) || f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile]) }
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "net-sftp", "~> 3.0"
  spec.add_dependency "x25519", ">= 1.0.7"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "json", "~> 2.6"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "pry", "~> 0.14"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
