# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains utility methods,
# that are used by I18n::Inflector and I18n::Backend::Inflector.

module I18n
  module Inflector
    module Util

      protected

      # Processes +locale+ name and validates
      # if it's correct (not empty and not +nil+).
      # 
      # @note If the +locale+ is not correct, it
      #   tries to use locale from {I18n.locale} and validates it
      #   as well.
      # @param [Symbol,String] locale the locale identifier
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [Symbol] the given locale or the global locale
      #   and usable or the global locale for I18n
      def inflector_prep_locale(locale=nil)
        locale ||= I18n.locale
        raise I18n::InvalidLocale.new(locale) if locale.to_s.empty?
        locale.to_sym
      end

    end
  end
end
