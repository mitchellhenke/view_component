# frozen_string_literal: true

# Run `bundle exec rake memory_benchmark` to execute benchmark.
# This is very much a work-in-progress. Please feel free to make/suggest improvements!

require "benchmark/ips"
require "memory_profiler"

# Configure Rails Environment
ENV["RAILS_ENV"] = "production"
require File.expand_path("../test/sandbox/config/environment.rb", __dir__)


module Performance
  require_relative "components/string_component"
end


class BenchmarksController < ActionController::Base
end

BenchmarksController.view_paths = [File.expand_path("./views", __dir__)]
controller_view = BenchmarksController.new.view_context

report = MemoryProfiler.report do
  1_000.times do
    controller_view.render(Performance::StringComponent.new)
  end
end

puts 'no freezing'
puts report.pretty_print($stdout, detailed_report: false)


ViewComponent::CompileCache.invalidate!
ViewComponent::Config.current.frozen_string_literal = true

frozen_report = MemoryProfiler.report do
  1_000.times do
    controller_view.render(Performance::StringComponent.new)
  end
end

puts 'freezing'
puts frozen_report.pretty_print($stdout, detailed_report: false)

puts "#{'%.2f' % (((frozen_report.total_allocated_memsize - report.total_allocated_memsize).to_f / report.total_allocated_memsize) * 100)}% difference in bytes allocated"
puts "#{'%.2f' % (((frozen_report.total_allocated - report.total_allocated).to_f / report.total_allocated) * 100)}% difference in object allocations"


ViewComponent::Config.current.frozen_string_literal = false
ViewComponent::CompileCache.invalidate!

Benchmark.ips do |x|
  x.time = 20
  x.warmup = 0

  x.report("not frozen") { controller_view.render(Performance::StringComponent.new) }
  ViewComponent::CompileCache.invalidate!
  ViewComponent::Config.current.frozen_string_literal = true
  x.report("frozen") { controller_view.render(Performance::StringComponent.new) }

  x.compare!
end
