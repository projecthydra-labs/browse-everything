# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'rubocop/rake_task'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

task default: [:ci]
