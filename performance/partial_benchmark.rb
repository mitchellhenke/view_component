# frozen_string_literal: true

# Run `bundle exec rake benchmark` to execute benchmark.
# This is very much a work-in-progress. Please feel free to make/suggest improvements!

require "benchmark/ips"

# Configure Rails Environment
ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)

module Performance
  require_relative "components/name_component"
  require_relative "components/nested_name_component"
  require_relative "components/inline_component"
end

class SkipBenchmarksController < ActionController::Base
  def skip
    true
  end
end

class NoSkipBenchmarksController < ActionController::Base
  def skip
    false
  end
end

SkipBenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
NoSkipBenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
skip_controller_view = SkipBenchmarksController.new.view_context
no_skip_controller_view = NoSkipBenchmarksController.new.view_context

Benchmark.ips do |x|
  x.time = 10
  x.warmup = 2

  x.report("component no skip") { no_skip_controller_view.render(Performance::NameComponent.new(name: "Fox Mulder")) }
  x.report("component skip") { skip_controller_view.render(Performance::NameComponent.new(name: "Fox Mulder")) }

  x.compare!
end


Benchmark.ips do |x|
  x.time = 10
  x.warmup = 2

  x.report("inline no skip") { no_skip_controller_view.render(Performance::InlineComponent.new(name: "Fox Mulder")) }
  x.report("inline skip") { skip_controller_view.render(Performance::InlineComponent.new(name: "Fox Mulder")) }

  x.compare!
end


Benchmark.ips do |x|
  x.time = 10
  x.warmup = 2

  x.report("partial no skip") { no_skip_controller_view.render("partial", name: "Fox Mulder") }
  x.report("partial skip") { skip_controller_view.render("partial", name: "Fox Mulder") }

  x.compare!
end
