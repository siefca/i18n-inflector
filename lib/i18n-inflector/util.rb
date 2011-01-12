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
      def inflector_prep_kl(kind=nil, locale=nil)
        locale ||= I18n.locale
        raise I18n::InvalidLocale.new(locale) if locale.to_s.empty?
        kind = kind.to_s.empty? ? nil : kind.to_sym
        [kind, locale.to_sym]
      end

      def tkl_args(args)
        token, kind, locale = case args.count
        when 1 then [args[0], nil, nil]
        when 2 then [args[0], nil, args[1]]
        when 3 then args
        else raise ArgumentError.new("wrong number of arguments: #{args.count} for (1..3)")
        end
        token   = token.to_s.empty? ? nil : token.to_sym
        kind    = kind.to_s.empty? ? kind : kind.to_sym
        locale  = inflector_prep_locale(locale)
        [token,kind,locale]
      end

    end
  end
end
