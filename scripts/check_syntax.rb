# frozen_string_literal: true
require 'rbconfig'
files = Dir['**/*.rb'].reject { |path| path.start_with?('vendor/') }
failed = files.reject { |path| system(RbConfig.ruby, '-c', path) }
abort "Syntax failures: #{failed.join(', ')}" unless failed.empty?
puts "Ruby syntax checked: #{files.length} files"
