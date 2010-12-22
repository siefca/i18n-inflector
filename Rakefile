# encoding: utf-8
# -*- ruby -*-
 
$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'rubygems'
gem 'hoe', '>=2.3.0'
gem 'hoe-bundler', '>=1.0.0'

require "rake"
require "rake/clean"
require "rake/testtask"

require "fileutils"
require 'i18n-inflector'

require 'hoe'

task :default => [:test]

desc "install by setup.rb"
task :install do
  sh "sudo ruby setup.rb install"
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = "#{File.dirname(__FILE__)}/test/all.rb"
  t.verbose = true
  t.warning = true
end
Rake::Task['test'].comment = "Run all i18n-inflector tests"

### Gem

Hoe.plugin :bundler

Hoe.spec 'i18n-inflector' do
  self.version         =  "1.0.0"
  self.rubyforge_name  = 'i18n-inflector'
  self.summary         = 'Simple Inflector backend module for I18n'
  self.description     = 'This backend module for I18n allows you to inflect translations by interpolating patterns.'
  self.url             = 'https://rubygems.org/gems/i18n-inflector/'

  developer           "Paweł Wilk", "pw@gnu.org"
  
  self.remote_rdoc_dir = ''
  self.rspec_options   = ['--options', 'spec/spec.opts']
  self.rsync_args      << '--chmod=a+rX'
  self.readme_file     = 'docs/README'
  self.history_file    = 'docs/HISTORY'

  self.extra_rdoc_files = ["docs/README",
                           "docs/LGPL-LICENSE",
                           "docs/LEGAL", "docs/HISTORY",
                           "docs/COPYING"]

  extra_deps          << ["i18n",">= 0.5.0"]
#  extra_dev_deps      << ['hoe', '>= 2.8.0']
  extra_dev_deps      << ['test_declarative', '>= 0.0.4']

  self.spec_extras['rdoc_options'] = proc do |rdoc_options|
      rdoc_options << "--title=Simple Inflector for I18n"
  end

end

task :docs do
  
  FileUtils.mv 'doc/rdoc.css', 'doc/rdoc_base.css'
  FileUtils.cp 'docs/rdoc.css', 'doc/rdoc.css'

end

task 'Manifest.txt' do
  puts 'generating Manifest.txt from git'
  sh %{git ls-files | grep -v gitignore > Manifest.txt}
  sh %{git add Manifest.txt}
end

task 'ChangeLog' do
  sh %{git log > ChangeLog}
end

desc "Fix documentation's file permissions"
task :docperm do
  sh %{chmod -R a+rX doc}
end

### Sign & Publish

desc "Create signed tag in Git"
task :tag do
  sh %{git tag -u #{I18n::Backend::Inflector::EMAIL} v#{I18n::Backend::Inflector::VERSION} -m 'version #{I18n::Backend::Inflector::VERSION}'}
end

desc "Create external GnuPG signature for Gem"
task :gemsign do
  sh %{gpg -u #{I18n::Backend::Inflector::EMAIL} -ab pkg/#{I18n::Backend::Inflector::NAME}-#{I18n::Backend::Inflector::VERSION}.gem \
           -o pkg/#{I18n::Backend::Inflector::NAME}-#{I18n::Backend::Inflector::VERSION}.gem.sig}
end

