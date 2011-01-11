# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Backend::Inflector module,
# which extends I18n::Backend::Simple by adding the ability
# to interpolate patterns containing inflection tokens
# defined in translation data.

module I18n
  module Backend
    module Inflector

      # Contains <tt>@{</tt> string that is used to quickly fallback
      # to standard +translate+ method if it's not found.
      FAST_MATCHER  = '@{'

      # Contains a regular expression that catches patterns.
      PATTERN       = /(.?)@\{([^\}]+)\}/

      # Contains a regular expression that catches tokens.
      TOKENS        = /(?:([^\:\|]+):+([^\|]+)\1?)|([^:\|]+)/ 

      # Contains a symbol that indicates an alias.
      ALIAS_MARKER  = '@'

      # Conatins a symbol used to separate multiple tokens.
      OPERATOR_MULTI = ','

      # Contains a list of escape symbols that cause pattern to be escaped.
      ESCAPES       = { '@' => true, '\\' => true }

      # Reserved keys
      INFLECTOR_RESERVED_KEYS = defined?(RESERVED_KEYS) ?
                                RESERVED_KEYS : I18n::Backend::Base::RESERVED_KEYS

      attr_accessor :inflector_raises
      attr_accessor :inflector_unknown_defaults
      attr_accessor :inflector_excluded_defaults

      # Checks the state of the switch that enables extended error reporting.
      # 
      # @api public
      # @note This is a helper method, you can use {#inflector_raises accessor} instead.
      # @return [Boolean] the value of the global switch or the passed variable
      # @see I18n::Inflector.raises? Short name: I18n::Inflector.raises?
      # @see #inflector_raises=
      # @overload inflector_raises?
      #   Checks the state of the switch that enables extended error reporting.
      #   @return [Boolean] the value of the global switch
      # @overload inflector_raises?(value)
      #   Returns the given value.
      #   @param [Boolean] value the value to be returned
      #   @return [Boolean] +true+ if the passed +value+ is not +false+
      def inflector_raises?(option=nil)
        option.nil? ? @inflector_raises : option!=false
      end

      # Checks the state of the switch that that enables falling back
      # to the default token of a kind when the inflection option
      # is unknown or empty.
      # 
      # @api public
      # @note This is a helper method, you can use {#inflector_unknown_defaults accessor} instead.
      # @return [Boolean] the value of the global switch or the passed variable
      # @see I18n::Inflector.unknown_defaults? Short name: I18n::Inflector.unknown_defaults?
      # @see #inflector_unknown_defaults=
      # @overload inflector_unknown_defaults?
      #   Checks the state of the switch that that enables falling back
      #   to the default token for a kind when the inflection option
      #   is unknown or empty.
      #   @return [Boolean] the value of the global switch
      # @overload inflector_unknown_defaults?(value)
      #   Returns the given value.
      #   @param [Boolean] value the value to be returned
      #   @return [Boolean] +true+ if the passed +value+ is not +false+
      def inflector_unknown_defaults?(option=nil)
        option.nil? ? @inflector_unknown_defaults : option!=false
      end
      
      # Checks the state of the switch that that enables falling back
      # to the default token when the inflection option is not found in a pattern.
      # 
      # @api public
      # @note This is a helper method, you can use {#inflector_excluded_defaults accessor} instead.
      # @return [Boolean] the value of the global switch or the passed variable
      # @see I18n::Inflector.excluded_defaults? Short name: I18n::Inflector.excluded_defaults?
      # @see #inflector_excluded_defaults=
      # @overload inflector_excluded_defaults?
      #   Checks the state of the switch that enables falling back
      #   to the default token for a kind when token name from
      #   the inflection option is not found in a pattern.
      #   @return [Boolean] the value of the global switch
      # @overload inflector_excluded_defaults?(value)
      #   Returns the given value
      #   @param [Boolean] value the value to be returned
      #   @return [Boolean] +true+ if the passed +value+ is not +false+
      def inflector_excluded_defaults?(option=nil)
        option.nil? ? @inflector_excluded_defaults : option!=false
      end
    
      # Cleans up internal hashes containg kinds, inflections and aliases.
      # 
      # @api public
      # @note It calls {I18n::Backend::Simple#reload! I18n::Backend::Simple#reload!}
      # @return [Boolean] the result of calling ancestor's method
      # @see I18n::Inflector.reload! Short name: I18n::Inflector.reload!
      def reload!
        @inflection_tokens    = nil
        @inflection_aliases   = nil
        @inflection_defaults  = nil
        super
      end

      # Translates given key taking care of inflections.
      # 
      # @api public
      # @param [Symbol] locale locale
      # @param [Symbol,String] key translation key
      # @param [Hash] options a set of options to pass to the translation routines.
      # @note Inflector requires at least one of the +options+ to have a value that
      #   corresponds with token present in a pattern (or its alias). The name of that
      #   particular option should be the same as the name of a kind of tokens from a pattern.
      #   All +options+ along with a +string+ and +locale+ are passed to
      #   {I18n::Backend::Simple#translate I18n::Backend::Simple#translate}
      #   and the result is processed by {#interpolate_inflections}
      # @return [String] the translated string with interpolated patterns
      def translate(locale, key, options = {})
        translated_string = super
        return translated_string if locale.to_s.empty?

        unless translated_string.include?(I18n::Backend::Inflector::FAST_MATCHER)
          return translated_string
        end

        inflection_tokens = @inflection_tokens[locale]
        if (inflection_tokens.nil? || inflection_tokens.empty?)
          return clear_inflection_patterns(translated_string)
        end

        interpolate_inflections(translated_string, locale, options.dup)
      end
      
      # Reads default token for the given +kind+.
      # 
      # @api public
      # @return [Symbol,nil] the default token for the given kind or +nil+
      # @raise [I18n::InvalidLocale] if the given +locale+ name is invalid
      # @see I18n::Inflector.default_token Short name: I18n::Inflector.default_token
      # @overload inflection_default_token(kind)
      #   This method reads default token for the given +kind+ and current locale.
      #   @param [Symbol] kind the kind of tokens
      #   @return [Symbol,nil] the default token for the given kind or +nil+ if
      #     there is no default token
      # @overload inflection_default_token(kind, locale)
      #   This method reads default token for the given +kind+ and the given +locale+.
      #   @param [Symbol] kind the kind of tokens
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the default token for the given kind or +nil+ if
      #     there is no default token
      def inflection_default_token(kind, locale=nil)
        locale = inflector_prep_locale(locale)
        return nil if kind.to_s.empty?
        init_translations unless initialized?
        inflections = @inflection_defaults[locale]
        return nil if inflections.nil?
        inflections[kind.to_sym]
      end

      # Checks if the given +token+ is an alias.
      # 
      # @api public
      # @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @see I18n::Inflector.is_alias? Short name: I18n::Inflector.is_alias?
      # @overload inflection_is_alias?(token)
      #   Uses current locale to check if the given +token+ is an alias
      #   or a regular token.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @overload inflection_is_alias?(token, locale)
      #   Uses the given +locale+ to check if the given +token+ is an alias
      #   or a regular token.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      def inflection_is_alias?(token, locale=nil)
        return false if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        init_translations unless initialized?
        aliases = @inflection_aliases[locale]
        return false if aliases.nil?
        aliases.has_key?(token.to_sym)
      end

      # Gets true token for the given +token+ (which may be an alias).
      # 
      # @api public
      # @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #   the token is a real token or +nil+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @see I18n::Inflector.true_token Short name: I18n::Inflector.true_token
      # @overload inflection_true_token(token)
      #   Uses current locale to get a real token for the given +token+.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #     the token is a real token or +nil+ otherwise
      # @overload inflection_true_token(token, locale)
      #   Uses the given +locale+ to get a real token for the given +token+.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #     the token is a real token or +nil+ otherwise
      def inflection_true_token(token, locale=nil)
        return nil if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        init_translations unless initialized?
        inflections = @inflection_tokens[locale]
        return nil if inflections.nil?
        entry = inflections[token]
        return token unless entry.nil?
        inflections = @inflection_aliases[locale]
        return nil if inflections.nil?
        entry = inflections[token]
        return nil if entry.nil?
        entry[:target]
      end

      # Gets a kind for the given +token+ (which may be an alias).
      # 
      # @api public
      # @return [Symbol,nil] the kind of the given +token+ or alias or +nil+
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @see I18n::Inflector.kind Short name: I18n::Inflector.kind
      # @overload inflection_true_token(token)
      #   Uses current locale to get a kind for the given +token+ which may be an alias.
      #   @param [Symbol,String] token name of the token or alias
      #   @return [Symbol,nil] the kind of the given +token+
      #     for the current locale
      # @overload inflection_true_token(token, locale)
      #   Uses the given +locale+ to get a kind for the given +token+ which may be an alias.
      #   @param [Symbol,String] token name of the token or alias
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the kind of the given +token+
      #     for the given +locale+
      def inflection_kind(token, locale=nil)
        return nil if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        init_translations unless initialized?
        inflections = @inflection_tokens[locale]
        return nil if inflections.nil?
        entry = inflections[token]
        return entry[:kind] unless entry.nil?
        inflections = @inflection_aliases[locale]
        return nil if inflections.nil?
        entry = inflections[token]
        return nil if entry.nil?
        entry[:kind]
      end

      # Gets available inflection tokens and their descriptions.
      # 
      # @api public
      # @see I18n::Inflector.tokens Short name: I18n::Inflector.tokens
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @return [Hash] the hash containing available inflection tokens and descriptions
      # @note You cannot deduce where aliases are pointing to, since the information
      #   about a target is replaced by the description. To get targets use the
      #   {#inflection_raw_tokens} method. To simply list aliases and their targets use
      #   the {#inflection_aliases} method.
      # @overload inflection_tokens
      #   Gets available inflection tokens and their descriptions.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases,
      #     for all kinds and current locale.
      # @overload inflection_tokens(kind)
      #   Gets available inflection tokens and their descriptions for some +kind+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale.
      # @overload inflection_tokens(kind, locale)
      #   Gets available inflection tokens and their descriptions for some +kind+ and +locale+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale
      def inflection_tokens(kind=nil, locale=nil)
        locale      = inflector_prep_locale(locale)
        true_tokens = inflection_true_tokens(kind, locale)
        aliases     = @inflection_aliases[locale]
        return true_tokens if aliases.nil?
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases = aliases.merge(aliases){|k,v| v[:description]}
        true_tokens.merge(aliases)
      end

      # Gets available inflection tokens and their values.
      # 
      # @api public
      # @see I18n::Inflector.raw_tokens Short name: I18n::Inflector.raw_tokens
      # @return [Hash] the hash containing available inflection tokens and descriptions (or alias pointers)
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @note You may deduce whether the returned values are aliases or true tokens
      #       by testing if a value is a type of Symbol or String.
      # @overload inflection_tokens_raw
      #   Gets available inflection tokens and their values.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values. In case of aliases the returned
      #     values are Symbols
      # @overload inflection_tokens_raw(kind)
      #   Gets available inflection tokens and their values for the given +kind+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+. In case of
      #     aliases the returned values are Symbols
      # @overload inflection_tokens_raw(kind, locale)
      #   Gets available inflection tokens and their values for the given +kind+ and +locale+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+ and +locale+.
      #     In case of aliases the returned values are Symbols
      def inflection_tokens_raw(kind=nil, locale=nil)
        true_tokens = inflection_true_tokens(kind, locale)
        aliases     = inflection_aliases(kind, locale)
        true_tokens.merge(aliases)
      end

      alias_method :inflection_raw_tokens, :inflection_tokens_raw

      # Gets true inflection tokens and their values.
      # 
      # @api public
      # @return [Hash] the hash containing available inflection tokens and descriptions
      # @see I18n::Inflector.true_tokens Short name: I18n::Inflector.true_tokens
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @note It returns only true tokens, not aliases.
      # @overload inflection_tokens_true
      #   Gets true inflection tokens and their values.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values
      # @overload inflection_tokens_true(kind)
      #   Gets true inflection tokens and their values for the given +kind+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+
      # @overload inflection_tokens_true(kind, locale)
      #   Gets true inflection tokens and their values for the given +kind+ and +value+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+ and +locale+
      def inflection_tokens_true(kind=nil, locale=nil)
        locale = inflector_prep_locale(locale)
        init_translations unless initialized?
        inflections = @inflection_tokens[locale]
        return {} if inflections.nil?
        inflections = inflections.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        inflections.merge(inflections){|k,v| v[:description]}
      end
      
      alias_method :inflection_true_tokens, :inflection_tokens_true

      # Gets inflection aliases and their pointers.
      # 
      # @api public
      # @see I18n::Inflector.aliases Short name: I18n::Inflector.aliases
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @return [Hash] the Hash containing available inflection aliases (<tt>alias => target</tt>)
      # @overload inflection_aliases
      #   Gets inflection aliases and their pointers.
      #   @return [Hash] the Hash containing available inflection aliases
      # @overload inflection_aliases(kind)
      #   Gets inflection aliases and their pointers for the given +kind+.
      #   @param [Symbol] kind the kind of aliases to get
      #   @return [Hash] the Hash containing available inflection
      #     aliases for the given +kind+ and current locale
      # @overload inflection_aliases(kind, locale)
      #   Gets inflection aliases and their pointers for the given +kind+ and +locale+.
      #   @param [Symbol] kind the kind of aliases to get
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the Hash containing available inflection
      #     aliases for the given +kind+ and +locale+
      def inflection_aliases(kind=nil, locale=nil)
        locale = inflector_prep_locale(locale)
        init_translations unless initialized?
        aliases = @inflection_aliases[locale]
        return {} if aliases.nil?
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases.merge(aliases){|k,v| v[:target]}
      end

      # Gets known inflection kinds.
      # 
      # @api public
      # @see I18n::Inflector.kinds Short name: I18n::Inflector.kinds
      # @return [Array<Symbol>] the array containing known inflection kinds
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @overload available_inflection_kinds
      #   Gets known inflection kinds for the current locale.
      #   @return [Array<Symbol>] the array containing known inflection kinds
      # @overload available_inflection_kinds(locale)
      #   Gets known inflection kinds for the given +locale+.
      #   @param [Symbol] locale the locale for which operation has to be done
      #   @return [Array<Symbol>] the array containing known inflection kinds
      def available_inflection_kinds(locale=nil)
        locale  = inflector_prep_locale(locale)
        init_translations unless initialized?
        subtree = inflection_subtree(locale)
        return [] if subtree.nil?
        subtree.keys
      end

      # Gets locales which have configured inflection support.
      # 
      # @api public
      # @see I18n::Inflector.locales Short name: I18n::Inflector.locales
      # @return [Array<Symbol>] the array containing locales that support inflection
      # @note If +kind+ is given it returns only these locales
      #   that are inflected and support inflection by this kind.
      def inflected_locales(kind=nil)
        init_translations unless initialized?
        inflected_locales = (@inflection_tokens.keys || [])
        return inflected_locales if kind.to_s.empty?
        kind = kind.to_sym
        inflected_locales.select do |loc|
          kinds = inflection_subtree(loc)
          kinds.respond_to?(:has_key?) && kinds.has_key?(kind)
        end
      end

      # Checks if a locale was configured to support inflection.
      # 
      # @api public
      # @see I18n::Inflector.locale? Short name: I18n::Inflector.locale?
      # @return [Boolean] +true+ if a locale supports inflection
      # @overload inflected_locale?(locale)
      #   Checks if the given locale was configured to support inflection.
      #   @param [Symbol] locale the locale to test
      #   @return [Boolean] +true+ if the given locale supports inflection
      # @overload inflected_locale?
      #   Checks if the current locale was configured to support inflection.
      #   @return [Boolean] +true+ if the current locale supports inflection
      def inflected_locale?(locale=nil)
        locale = inflector_prep_locale(locale) rescue nil
        return false if locale.nil?
        init_translations unless initialized?
        @inflection_tokens.has_key?(locale)
      end

      # Stores translations in memory.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @raise [I18n::BadInflectionToken] if a name of some loaded token is invalid
      # @raise [I18n::BadInflectionAlias] if a loaded alias points to a token that does not exists
      # @raise [I18n::DuplicatedInflectionToken] if a token has already appeard in loaded configuration
      # @note If inflections are changed it will regenerate proper internal
      #   structures.
      # @return [Hash] the stored translations 
      def store_translations(locale, data, options = {})
        r = super
        locale = inflector_prep_locale(locale)
        inflector_try_init
        if data.respond_to?(:has_key?)
          subdata = (data[:i18n] || data['i18n'])
          unless subdata.nil?
            subdata = (subdata[:inflections] || subdata['inflections'])
            unless subdata.nil?
              @inflection_tokens.delete   locale
              @inflection_aliases.delete  locale
              @inflection_defaults.delete locale
              load_inflection_tokens(locale, r[:i18n][:inflections])
            end
          end
        end
        r
      end

      # Gets the description of the given inflection token.
      # 
      # @api public
      # @see I18n::Inflector.description Short name: I18n::Inflector.description
      # @note If the given +token+ is really an alias it
      #   returns the description of the true token that
      #   it points to.
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @return [String,nil] the descriptive string or +nil+
      # @overload inflection_token_description(token)
      #   Uses current locale to get description of the given token.
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found)
      # @overload inflection_token_description(token, locale)
      #   Uses the given +locale+ to get description of the given inflection token.
      #   @param [Symbol] locale the locale to use
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found)
      def inflection_token_description(token, locale=nil)
        locale = inflector_prep_locale(locale)
        return nil if token.to_s.empty?
        init_translations unless initialized?
        inflections = @inflection_tokens[locale]
        aliases     = @inflection_aliases[locale]
        return nil if (inflections.nil? || aliases.nil?)
        token = token.to_sym
        match = (inflections[token] || aliases[token])
        return nil if match.nil?
        match[:description]
      end

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

      # Interpolates inflection values in a given +string+
      # using kinds given in +options+ and a matching tokens.
      # 
      # @param [String] string the translation string
      #  containing patterns to interpolate
      # @param [String,Symbol] locale the locale identifier 
      # @param [Hash] options the options
      # @option options [Boolean] :inflector_excluded_defaults (false) local switch
      #   that overrides global setting (see: {#inflector_excluded_defaults})
      # @option options [Boolean] :inflector_unknown_defaults (true) local switch
      #   that overrides global setting (see: {#inflector_unknown_defaults})
      # @option options [Boolean] :inflector_raises (false) local switch
      #   that overrides global setting (see: {#inflector_raises})
      # @return [String] the string with interpolated patterns
      def interpolate_inflections(string, locale, options = {})
        used_kinds        = options.except(*I18n::Backend::Inflector::INFLECTOR_RESERVED_KEYS)
        raises            = inflector_raises?             options.delete(:inflector_raises)
        unknown_defaults  = inflector_unknown_defaults?   options.delete(:inflector_unknown_defaults)
        excluded_defaults = inflector_excluded_defaults?  options.delete(:inflector_excluded_defaults)
        inflections       = @inflection_tokens[locale]
        defaults          = @inflection_defaults[locale]
        aliases           = @inflection_aliases[locale]

        string.gsub(I18n::Backend::Inflector::PATTERN) do
          pattern_fix     = $1
          pattern_content = $2
          ext_pattern     = $&
          parsed_kind     = nil
          ext_value       = nil
          ext_freetext    = ''
          found           = false
          parsed_default_v= nil

          # leave escaped pattern as is
          next ext_pattern[1..-1] if I18n::Backend::Inflector::ESCAPES.has_key?(pattern_fix)

          # process pattern content's
          pattern_content.scan(I18n::Backend::Inflector::TOKENS) do
            ext_token     = $1.to_s
            ext_value     = $2.to_s
            ext_freetext  = $3.to_s
            tokens        = Hash.new(false)
            kind          = nil
            option        = nil

            # token not found?
            if ext_token.empty?
              # free text not found too? that should never happend.
              if ext_freetext.empty?
                raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
              end
              next
            end

            # split tokens if comma is present and put to fast list
            ext_token.split(I18n::Backend::Inflector::OPERATOR_MULTI).each do |t|
              # token name corrupted
              if t.empty?
                raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
                next
              end

              # get kind for that token
              t     = t.to_sym
              kind  = inflections[t]
              if kind.nil?
                raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
                next
              end
              kind = kind[:kind]

              # set processed kind after matching first token in a pattern
              if parsed_kind.nil?
                parsed_kind = kind
              elsif parsed_kind != kind
                # different kinds in one pattern are prohibited
                raise I18n::MisplacedInflectionToken.new(ext_pattern, t, parsed_kind) if raises
                next
              end

              # use that token
              tokens[t] = true
            end

            # self-explanatory
            if tokens.empty?
              raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
            end

            # memorize default option for further processing
            default_token = defaults[kind]

            # fetch the kind's option or fetch default if an option does not exists
            option = options.has_key?(kind) ? options[kind] : default_token

            if option.to_s.empty?
              # if option is given but is unknown, empty or nil
              # then use default option for a kind if unknown_defaults is switched on
              option = unknown_defaults ? default_token : nil
            else
              # validate option and if it's unknown try in aliases
              option = option.to_sym
              unless inflections.has_key?(option)
                option = aliases[option]
                if option.nil?
                  # if still nothing then fall back to default value
                  # for a kind in unknown_defaults switch is on
                  option = unknown_defaults ? default_token : nil
                else
                  option = option[:target]
                end
              end
            end

            # if the option is still unknown
            if option.nil?
              raise I18n::InvalidOptionForKind.new(ext_pattern, kind, ext_token, nil) if raises
              next
            end

            # memorize default token's value for further processing
            # outside this block if excluded_defaults switch is on
            parsed_default_v = ext_value if (excluded_defaults && tokens[default_token])

            # throw the value if a given option matches one of the tokens from group
            next unless tokens[option]

            # skip further evaluation of the pattern
            # since the right token has been found
            found = true
            break

          end # single token (or a group) processing

          result = nil

          # return value of a token that matches option's value
          # given for a kind or try to return a free text
          # if it's present
          if found
            result = ext_value
          elsif (excluded_defaults && !parsed_kind.nil?)
            # if there is excluded_defaults switch turned on
            # and a correct token was found in options but
            # has not been found in a pattern then interpolate
            # the pattern with a value picked for the default
            # token for that kind if a default token was present
            # in a pattern
            kind    = nil
            token   = options[parsed_kind]
            kind    = inflections[token]  unless token.nil?
            result  = parsed_default_v    unless (kind.nil? || kind[:kind].nil?)
          end

          pattern_fix + (result || ext_freetext)

        end # single pattern processing
      
      end

      # Initializes internal hashes used for keeping inflections configuration.
      # 
      # @return [void]
      def inflector_try_init
        return nil if (defined?(@inflection_tokens) && !@inflection_tokens.nil?)
        @inflection_tokens            = {}
        @inflection_aliases         ||= {}
        @inflection_defaults        ||= {}
        @inflector_excluded_defaults  = false
        @inflector_unknown_defaults   = true
        @inflector_raises             = false
        nil
      end

      # Takes care of loading inflection tokens
      # for all languages (locales) that have them
      # defined.
      # 
      # @note It calls {I18n::Backend::Simple#init_translations I18n::Backend::Simple#init_translations}
      # @raise [I18n::BadInflectionToken] if a name of some loaded token is invalid
      # @raise [I18n::BadInflectionAlias] if a loaded alias points to a token that does not exists
      # @raise [I18n::DuplicatedInflectionToken] if a token has already appeard in loaded configuration
      # @return [Boolean] +true+ if everything went fine
      def init_translations
        inflector_try_init
        super
      end

      # Removes inflection patterns from the translated string.
      # 
      # @param [String] translated_string the string that is translated
      # @return [String] the translation with any inflection patterns removed
      def clear_inflection_patterns(translated_string)
        translated_string.gsub(I18n::Backend::Inflector::PATTERN,'')
      end

      # Gives access to the internal structure containing configuration data
      # for a given locale.
      # 
      # @note Under some very rare conditions this method may be called while
      #   translation data is loading. It must always return when translations
      #   are not initialized. Otherwise it will cause loops and someone in Poland
      #   will eat a kittien!
      # @param [Symbol] locale the locale to use
      # @return [Hash,nil] part of the translation data that
      #   reflects inflections for a given locale or +nil+
      #   if translations are not initialized
      def inflection_subtree(locale)
        return nil unless initialized?
        lookup(locale, :"i18n.inflections", [], :fallback => true, :raise => :false)
      end

      # Resolves an alias for a token if the given +token+ is an alias.
      # 
      # @note It does take care of aliasing loops (max traverses is set to 64).
      # @raise [I18n::BadInflectionToken] if a name of the token that alias points to is corrupted
      # @raise [I18n::BadInflectionAlias] if an alias points to token that does not exists
      # @return [Symbol] the true token that alias points to if the given +token+
      #   is an alias or the given +token+ if it is a true token
      # @overload shorten_inflection_alias(token, kind, locale)
      #   Resolves an alias for a token if the given +token+ is an alias for the given +locale+ and +kind+.
      #   @note This version uses internal subtree and needs the translation data to be initialized.
      #   @param [Symbol] token the token name
      #   @param [Symbol] kind the kind of the given token
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol] the true token that alias points to if the given +token+
      #     is an alias or the given +token+ if it is a true token
      # @overload shorten_inflection_alias(token, kind, locale, subtree)
      #   Resolves an alias for a token if the given +token+ is an alias for the given +locale+ and +kind+.
      #   @param [Symbol] token the token name
      #   @param [Symbol] kind the kind of the given token
      #   @param [Symbol] locale the locale to use
      #   @param [Hash] subtree the tree (in a form of nested Hashes) containing inflection tokens to scan
      #   @return [Symbol] the true token that alias points to if the given +token+
      #     is an alias or the given +token+ if it is a true token
      def shorten_inflection_alias(token, kind, locale, subtree=nil, count=0)
        count += 1
        return nil if count > 64
  
        inflections_tree = subtree || inflection_subtree(locale)
        return nil if (inflections_tree.nil? || inflections_tree.empty?)

        kind_subtree  = inflections_tree[kind]
        value         = kind_subtree[token].to_s

        if value.slice(0,1) != I18n::Backend::Inflector::ALIAS_MARKER
          if kind_subtree.has_key?(token)
            return token
          else
            # that should never happend but who knows
            raise I18n::BadInflectionToken.new(locale, token, kind)
          end
        else
          orig_token = token
          token = value[1..-1]
          if token.to_s.empty?
            raise I18n::BadInflectionToken.new(locale, token, kind)
          end
          token = token.to_sym
          if kind_subtree[token].nil?
            raise BadInflectionAlias.new(locale, orig_token, kind, token)
          else
            shorten_inflection_alias(token, kind, locale, inflections_tree, count)
          end
        end

      end

      # Uses the inflections subtree and creates internal mappings
      # to resolve kinds assigned to inflection tokens and aliases, including defaults.
      # @return [Hash,nil] the internal Hash containing inflection tokens or +nil+ if something went wrong
      # @raise [I18n::BadInflectionToken] if a name of some loaded token is invalid
      # @raise [I18n::BadInflectionAlias] if a loaded alias points to a token that does not exists
      # @raise [I18n::DuplicatedInflectionToken] if a token has already appeard in loaded configuration
      # @overload load_inflection_tokens(locale)
      #   @note That version calls the {inflection_subtree} method to obtain internal translations data.
      #   Loads inflection tokens for the given locale using internal hash of stored translations. Requires
      #   translations to be initialized.
      #   @param [Symbol] locale the locale to use and work for
      #   @return [Hash,nil] the internal Hash containing inflection tokens (<tt>token => kind</tt>)
      #     or +nil+ if translations were not initialized
      # @overload load_inflection_tokens(locale, subtree)
      #   Loads inflection tokens for the given locale using data given in an argument
      #   @param [Symbol] locale the locale to use and work for
      #   @param [Hash] subtree the tree (in a form of nested Hashes) containing inflection tokens to scan
      #   @return [Hash,nil] the internal Hash containing inflection tokens (<tt>token => kind</tt>)
      #   or +nil+ if the given subtree was wrong or empty
      def load_inflection_tokens(locale, subtree=nil)
        return @inflection_tokens[locale] if @inflection_tokens.has_key?(locale)
        inflections_tree = subtree || inflection_subtree(locale)
        return nil if (inflections_tree.nil? || inflections_tree.empty?)
        ivars     = @inflection_tokens[locale]    = {}
        aliases   = @inflection_aliases[locale]   = {}
        defaults  = @inflection_defaults[locale]  = {}

        inflections_tree.each_pair do |kind, tokens|
          tokens.each_pair do |token, description|
            
            # test for duplicate
            if ivars.has_key?(token)
              raise I18n::DuplicatedInflectionToken.new(ivars[token], kind, token)
            end

            # validate token's name
            if token.nil?
              raise I18n::BadInflectionToken.new(locale, token, kind)
            end

            # validate token's description
            if description.nil?
              raise I18n::BadInflectionToken.new(locale, token, kind, description)
            end

            # handle default token for a kind
            if token == :default
              if defaults.has_key?(kind) # should never happend unless someone is messing with @translations
                raise I18n::DuplicatedInflectionToken.new(kind, nil, token)
              end
              defaults[kind] = description.to_sym
              next
            end

            # handle alias
            if description.slice(0,1) == I18n::Backend::Inflector::ALIAS_MARKER
              real_token = shorten_inflection_alias(token, kind, locale, inflections_tree)
              unless real_token.nil?
                real_token = real_token.to_sym
                aliases[token] = {}
                aliases[token][:kind]         = kind
                aliases[token][:target]       = real_token
                aliases[token][:description]  = inflections_tree[kind][real_token].to_s
              end
              next
            end

            ivars[token] = {}
            ivars[token][:kind]         = kind.to_sym
            ivars[token][:description]  = description.to_s
          end
        end

        # validate defaults
        defaults.each_pair do |kind, pointer|
          unless ivars.has_key?(pointer)
            # default may be an alias
            target = aliases[pointer]
            target = target[:target] unless target.nil?
            real_token = (target || shorten_inflection_alias(:default, kind, locale, inflections_tree))
            raise I18n::BadInflectionAlias.new(locale, :default, kind, pointer) if real_token.nil?
            defaults[kind] = real_token.to_sym            
          end
        end

        ivars
      end

    end
  end
  
  
end
