# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Inflector module,
# which adds wrappers (module functions) for methods
# in I18n::Backend::Inflector module in order to
# access common methods under friendly names.
# 

module I18n
  module Inflector

    class <<self
      # {include:I18n::Backend::Inflector#inflector_raises?}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_raises?}
      # @return [Boolean] the current state of the switch
      def raises?(*args);             I18n.backend.inflector_raises?(*args)             end

      # {include:I18n::Backend::Inflector#inflector_raises=}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_raises=}
      # @return [Boolean] the current state of the switch
      def raises=(*args);             I18n.backend.inflector_raises = *args             end

      # {include:I18n::Backend::Inflector#inflector_raises}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_raises}
      # @return [Boolean] the current state of the switch
      def raises(*args);              I18n.backend.inflector_raises(*args)              end

      # {include:I18n::Backend::Inflector#inflector_unknown_defaults?}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_unknown_defaults?}
      # @return [Boolean] the current state of the switch
      def unknown_defaults?(*args);   I18n.backend.inflector_unknown_defaults?(*args)   end

      # {include:I18n::Backend::Inflector#inflector_unknown_defaults=}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_unknown_defaults=}
      # @return [Boolean] the current state of the switch
      def unknown_defaults=(*args);   I18n.backend.inflector_unknown_defaults = *args   end

      # {include:I18n::Backend::Inflector#inflector_unknown_defaults}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_unknown_defaults}
      # @return [Boolean] the current state of the switch
      def unknown_defaults(*args);    I18n.backend.inflector_unknown_defaults(*args)    end

      # {include:I18n::Backend::Inflector#inflector_excluded_defaults?}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_excluded_defaults?}
      # @return [Boolean] the current state of the switch
      def excluded_defaults?(*args);  I18n.backend.inflector_excluded_defaults?(*args)  end

      # {include:I18n::Backend::Inflector#inflector_excluded_defaults=}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_excluded_defaults=}
      # @return [Boolean] the current state of the switch
      def excluded_defaults=(*args);  I18n.backend.inflector_excluded_defaults = *args  end

      # {include:I18n::Backend::Inflector#inflector_excluded_defaults}
      # @api public
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_excluded_defaults}
      # @return [Boolean] the current state of the switch
      def excluded_defaults(*args);   I18n.backend.inflector_excluded_defaults(*args)   end
          
    end

  end
end
