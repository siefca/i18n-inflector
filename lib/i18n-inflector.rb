require 'i18n'
require 'i18n-inflector/inflector.rb'
require 'i18n-inflector/shortcuts.rb'

I18n::Backend::Simple.send(:include, I18n::Backend::Inflector)
