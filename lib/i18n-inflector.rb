# encoding: utf-8

require 'i18n'
require 'i18n-inflector/errors.rb'
require 'i18n-inflector/inflector.rb'

I18n::Backend::Simple.send(:include, I18n::Backend::Inflector)

require 'i18n-inflector/shortcuts.rb'

module I18n
  module Backend
    module Inflector

      # @private
      DEVELOPER   = 'Paweł Wilk'
      # @private
      EMAIL       = 'pw@gnu.org'
      # @private
      VERSION     = '1.0.5'
      # @private
      NAME        = 'i18n-inflector'
      # @private
      SUMMARY     = 'Simple Inflector backend module for I18n'
      # @private
      URL         = 'https://rubygems.org/gems/i18n-inflector/'
      # @private
      DESCRIPTION = 'This backend module for I18n inflects translations using pattern interpolation.'

    end
  end
end

