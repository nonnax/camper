require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

spec=Gem::Specification.new do |s|
  s.name = %q{camper}
  s.version = "0.1.1"
  s.date = Time.now.strftime("%x")
  s.summary = %q{Camper}
  s.email = %q{ironald@gmail.com}
  s.homepage = %q{http://http://www.google.com/group/object_id}
  s.description = %q{Camper: Simple camping deployment}
  s.has_rdoc = true
  s.authors = ["Ronald Evangelista"]
  s.files =   %w|Rakefile README CHANGELOG lib/camper.rb lib/camper_page_caching.rb lib/camper_helpers.rb|
  s.add_dependency(%q<camping>, [">= 1.9.0"])
end

desc 'Create Gem Package'
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = false

end

task :default=>[:package]
