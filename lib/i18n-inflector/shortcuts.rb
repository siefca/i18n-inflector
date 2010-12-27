# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2010 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Inflector module,
# which adds wrappers (module functions) for methods
# in I18n::Backend::Inflector module in order to
# access common methods under friendly names.
# 

module I18n
  
  # @abstract It groups methods that are shortcuts to registered backend methods.
  module Inflector

    class <<self
      # {include:I18n::Backend::Inflector#inflector_raises?}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_raises?}
      # @return [Boolean] the current state of the switch
      def raises?(*args);             I18n.backend.inflector_raises?(*args)             end

      # {include:I18n::Backend::Inflector#inflector_raises=}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_raises=}
      # @return [Boolean] the current state of the switch
      def raises=(*args);             I18n.backend.inflector_raises = *args             end

      # {include:I18n::Backend::Inflector#inflector_raises}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_raises}
      # @return [Boolean] the current state of the switch
      def raises(*args);              I18n.backend.inflector_raises(*args)              end

      # {include:I18n::Backend::Inflector#inflector_unknown_defaults?}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_unknown_defaults?}
      # @return [Boolean] the current state of the switch
      def unknown_defaults?(*args);   I18n.backend.inflector_unknown_defaults?(*args)   end

      # {include:I18n::Backend::Inflector#inflector_unknown_defaults=}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_unknown_defaults=}
      # @return [Boolean] the current state of the switch
      def unknown_defaults=(*args);   I18n.backend.inflector_unknown_defaults = *args   end
      
      # {include:I18n::Backend::Inflector#inflector_unknown_defaults}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_unknown_defaults}
      # @return [Boolean] the current state of the switch
      def unknown_defaults(*args);    I18n.backend.inflector_unknown_defaults(*args)    end

      # {include:I18n::Backend::Inflector#inflector_excluded_defaults?}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_excluded_defaults?}
      # @return [Boolean] the current state of the switch
      def excluded_defaults?(*args);  I18n.backend.inflector_excluded_defaults?(*args)  end

      # {include:I18n::Backend::Inflector#inflector_excluded_defaults=}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_excluded_defaults=}
      # @return [Boolean] the current state of the switch
      def excluded_defaults=(*args);  I18n.backend.inflector_excluded_defaults = *args  end
      
      # {include:I18n::Backend::Inflector#inflector_excluded_defaults}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflector_excluded_defaults}
      # @return [Boolean] the current state of the switch
      def excluded_defaults(*args);   I18n.backend.inflector_excluded_defaults(*args)   end

      # {include:I18n::Backend::Inflector#reload!}
      # @note It's a shortcut for {I18n::Backend::Inflector#reload!}
      # @return [void]
      def reload!;                    I18n.backend.reload!                              end

      # {include:I18n::Backend::Inflector#inflection_default_token}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_default_token}
      # @return [Symbol] the default token for the given kind
      def default_token(*args);       I18n.backend.inflection_default_token(*args)      end

      # {include:I18n::Backend::Inflector#inflection_is_alias?}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_is_alias?}
      # @return [Boolean] +true+ if the given token is really an alias
      def is_alias?(*args);           I18n.backend.inflection_is_alias?(*args)          end

      # {include:I18n::Backend::Inflector#inflection_tokens}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_tokens}
      # @return [Hash] the Hash containing available inflection tokens (with aliases) and their descriptions
      def tokens(*args);              I18n.backend.inflection_tokens(*args)             end

      # {include:I18n::Backend::Inflector#inflection_tokens_raw}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_tokens_raw}
      # @return [Hash] the Hash containing available inflection tokens and their values (descriptions, alias pointers)
      def raw_tokens(*args);          I18n.backend.inflection_tokens_raw(*args)         end

      # {include:I18n::Backend::Inflector#inflection_tokens_true}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_tokens_true}
      # @return [Hash] the Hash containing available inflection tokens (without aliases) and their descriptions
      def true_tokens(*args);         I18n.backend.inflection_tokens_true(*args)        end

      # {include:I18n::Backend::Inflector#inflection_aliases}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_aliases}
      # @return [Hash] the Hash containing available inflection aliases
      def aliases(*args);             I18n.backend.inflection_aliases(*args)            end

      # {include:I18n::Backend::Inflector#available_inflection_kinds}
      # @note It's a shortcut for {I18n::Backend::Inflector#available_inflection_kinds}
      # @return [Array<Symbol>] the array containing known inflection kinds
      def kinds(*args);               I18n.backend.available_inflection_kinds(*args)    end

      # {include:I18n::Backend::Inflector#inflected_locales}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflected_locales}
      # @return [Array<Symbol>] the array containing locales that support inflection
      def locales(*args);             I18n.backend.inflected_locales(*args)             end

      # {include:I18n::Backend::Inflector#inflection_token_description}
      # @note It's a shortcut for {I18n::Backend::Inflector#inflection_token_description}
      # @return [String,nil] the descriptive string or +nil+
      def description(*args);         I18n.backend.inflection_token_description(*args)  end
    end

  end
end
