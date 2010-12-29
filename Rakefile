# encoding: utf-8
# -*- ruby -*-
 
$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'rubygems'
require 'bundler/setup'

require "rake"
require "rake/clean"

require "fileutils"
require 'i18n-inflector'

require 'hoe'

task :default => [:test]

desc "install by setup.rb"
task :install do
  sh "sudo ruby setup.rb install"
end

### Gem

Hoe.plugin :bundler
Hoe.plugin :yard

Hoe.spec 'i18n-inflector' do
  developer               I18n::Backend::Inflector::DEVELOPER, I18n::Backend::Inflector::EMAIL

  self.version         =  I18n::Backend::Inflector::VERSION
  self.rubyforge_name  =  I18n::Backend::Inflector::NAME
  self.summary         =  I18n::Backend::Inflector::SUMMARY
  self.description     =  I18n::Backend::Inflector::DESCRIPTION
  self.url             =  I18n::Backend::Inflector::URL

  self.test_globs       = %w(test/**/*_test.rb)

  self.remote_rdoc_dir = ''
  self.rsync_args      << '--chmod=a+rX'
  self.readme_file     = 'README.rdoc'
  self.history_file    = 'docs/HISTORY'
  
  extra_deps          << ['i18n',             '>= 0.4.1']
  extra_dev_deps      << ['test_declarative', '>= 0.0.4'] <<
                         ['yard',             '>= 0.6.4'] <<
                         ['bundler',          '>= 1.0.7'] <<
                         ['hoe-bundler',      '>= 1.0.0']
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

