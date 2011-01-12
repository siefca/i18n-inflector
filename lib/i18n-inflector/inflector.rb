# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Inflector module,
# which extends I18n by adding the ability
# to interpolate patterns containing inflection tokens
# defined in translation data and manipulate on that data.

module I18n
  module Inflector

    extend I18n::Inflector::Util

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

    # Conatins a symbol used to mark tokens as negative.
    OPERATOR_NOT  = '!'

    # Contains a list of escape symbols that cause pattern to be escaped.
    ESCAPES       = { '@' => true, '\\' => true }

    # Reserved keys
    INFLECTOR_RESERVED_KEYS = defined?(RESERVED_KEYS) ?
                              RESERVED_KEYS : I18n::Backend::Base::RESERVED_KEYS

    class <<self
      # Cleans up internal hashes containg kinds, inflections and aliases.
      # 
      # @api public
      # @note It calls {I18n::Backend::Simple#reload! I18n::Backend::Simple#reload!}
      # @return [Boolean] the result of calling ancestor's method
      def reload!
        I18n.backend.reload!
      end

      # Reads default token for the given +kind+.
      # 
      # @api public
      # @return [Symbol,nil] the default token for the given kind or +nil+
      # @raise [I18n::InvalidLocale] if the given +locale+ name is invalid
      # @overload default_token(kind)
      #   This method reads default token for the given +kind+ and current locale.
      #   @param [Symbol] kind the kind of tokens
      #   @return [Symbol,nil] the default token for the given kind or +nil+ if
      #     there is no default token
      # @overload default_token(kind, locale)
      #   This method reads default token for the given +kind+ and the given +locale+.
      #   @param [Symbol] kind the kind of tokens
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the default token for the given kind or +nil+ if
      #     there is no default token
      def default_token(kind, locale=nil)
        locale = inflector_prep_locale(locale)
        return nil if kind.to_s.empty?
        I18n.backend.inflector_try_init_backend
        inflections = @inflection_defaults[locale]
        return nil if inflections.nil?
        inflections[kind.to_sym]
      end

      # Checks if the given +token+ is an alias.
      # 
      # @api public
      # @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @overload is_alias?(token)
      #   Uses current locale to check if the given +token+ is an alias.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @overload is_alias?(token, locale)
      #   Uses the given +locale+ to check if the given +token+ is an alias.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @overload is_alias?(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to check if the given +token+ is an alias.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      def is_alias?(*args)
        token, kind, locale = tkl_args(args)
        return false if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        ialiases = @inflection_aliases[locale]
        return false if ialiases.nil?
        ialiases.has_key?(token.to_sym)
      end
      alias_method :token_is_alias?, :is_alias?

      # Checks if the given +token+ is a true token (not alias).
      # 
      # @api public
      # @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @overload is_true_token?(token)
      #   Uses current locale to check if the given +token+ is a true token.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @overload is_true_token?(token, locale)
      #   Uses the given +locale+ to check if the given +token+ is a true token.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @overload is_true_token?(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to check if the given +token+ is a true token.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      def is_true_token?(*args)
        token, kind, locale = tkl_args(args)
        return false if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        itokens = @inflection_tokens[locale]
        return false if itokens.nil?
        itokens.has_key?(token.to_sym)
      end
      alias_method :token_is_true?, :is_true_token?

       # Checks if the given +token+ exists. It may be an alias or a true token.
       # 
       # @api public
       # @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
       # @overload is_token?(token)
       #   Uses current locale to check if the given +token+ is a token.
       #   @param [Symbol,String] token name of the checked token
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @overload is_token?(token, locale)
       #   Uses the given +locale+ to check if the given +token+ exists.
       #   @param [Symbol,String] token name of the checked token
       #   @param [Symbol] locale the locale to use
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @overload is_token?(token, kind, locale)
       #   Uses the given +locale+ and +kind+ to check if the given +token+ exists.
       #   @param [Symbol,String] token name of the checked token
       #   @param [Symbol] kind the kind used to narrow the check
       #   @param [Symbol] locale the locale to use
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       def is_token?(*args)
         token, kind, locale = tkl_args(args)
         return false if token.to_s.empty?
         locale = inflector_prep_locale(locale)
         I18n.backend.inflector_try_init_backend
         itokens = @inflection_tokens[locale]
         return true if (!itokens.nil? && itokens.has_key?(token.to_sym))
         ialiases = @inflection_aliases[locale]
         return true if (!ialiases.nil? && ialiases.has_key?(token.to_sym))
         return false
       end
       alias_method :token_exists?, :is_token?

      # Gets true token for the given +token+ (which may be an alias).
      # 
      # @api public
      # @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #   the token is a real token or +nil+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @overload true_token(token)
      #   Uses current locale to get a real token for the given +token+.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #     the token is a real token or +nil+ otherwise
      # @overload true_token(token, locale)
      #   Uses the given +locale+ to get a real token for the given +token+.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #     the token is a real token or +nil+ otherwise
      def true_token(token, locale=nil)
        return nil if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
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
      alias_method :get_true_token, :true_token

      # Gets a kind for the given +token+ (which may be an alias).
      # 
      # @api public
      # @return [Symbol,nil] the kind of the given +token+ or alias or +nil+
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @overload true_token(token)
      #   Uses current locale to get a kind for the given +token+ which may be an alias.
      #   @param [Symbol,String] token name of the token or alias
      #   @return [Symbol,nil] the kind of the given +token+
      #     for the current locale
      # @overload true_token(token, locale)
      #   Uses the given +locale+ to get a kind for the given +token+ which may be an alias.
      #   @param [Symbol,String] token name of the token or alias
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the kind of the given +token+
      #     for the given +locale+
      def kind(token, locale=nil)
        return nil if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
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
      alias_method :get_kind, :kind

      # Gets available inflection tokens and their descriptions.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @return [Hash] the hash containing available inflection tokens and descriptions
      # @note You cannot deduce where aliases are pointing to, since the information
      #   about a target is replaced by the description. To get targets use the
      #   {#inflection_raw_tokens} method. To simply list aliases and their targets use
      #   the {#inflection_aliases} method.
      # @overload tokens
      #   Gets available inflection tokens and their descriptions.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases,
      #     for all kinds and current locale.
      # @overload tokens(kind)
      #   Gets available inflection tokens and their descriptions for some +kind+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale.
      # @overload tokens(kind, locale)
      #   Gets available inflection tokens and their descriptions for some +kind+ and +locale+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale
      def tokens(kind=nil, locale=nil)
        locale      = inflector_prep_locale(locale)
        true_tokens = true_tokens(kind, locale)
        aliases     = @inflection_aliases[locale]
        return true_tokens if aliases.nil?
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases = aliases.merge(aliases){|k,v| v[:description]}
        true_tokens.merge(aliases)
      end

      # Gets available inflection tokens and their values.
      # 
      # @api public
      # @return [Hash] the hash containing available inflection tokens and descriptions (or alias pointers)
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @note You may deduce whether the returned values are aliases or true tokens
      #       by testing if a value is a type of Symbol or String.
      # @overload tokens_raw
      #   Gets available inflection tokens and their values.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values. In case of aliases the returned
      #     values are Symbols
      # @overload tokens_raw(kind)
      #   Gets available inflection tokens and their values for the given +kind+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+. In case of
      #     aliases the returned values are Symbols
      # @overload tokens_raw(kind, locale)
      #   Gets available inflection tokens and their values for the given +kind+ and +locale+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+ and +locale+.
      #     In case of aliases the returned values are Symbols
      def tokens_raw(kind=nil, locale=nil)
        true_tokens = true_tokens(kind, locale)
        aliases     = aliases(kind, locale)
        true_tokens.merge(aliases)
      end
      alias_method :raw_tokens, :tokens_raw

      # Gets true inflection tokens and their values.
      # 
      # @api public
      # @return [Hash] the hash containing available inflection tokens and descriptions
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @note It returns only true tokens, not aliases.
      # @overload tokens_true
      #   Gets true inflection tokens and their values.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values
      # @overload tokens_true(kind)
      #   Gets true inflection tokens and their values for the given +kind+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+
      # @overload tokens_true(kind, locale)
      #   Gets true inflection tokens and their values for the given +kind+ and +value+.
      #   @param [Symbol] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+ and +locale+
      def tokens_true(kind=nil, locale=nil)
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        inflections = @inflection_tokens[locale]
        return {} if inflections.nil?
        inflections = inflections.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        inflections.merge(inflections){|k,v| v[:description]}
      end
      alias_method :true_tokens, :tokens_true

      # Gets inflection aliases and their pointers.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @return [Hash] the Hash containing available inflection aliases (<tt>alias => target</tt>)
      # @overload aliases
      #   Gets inflection aliases and their pointers.
      #   @return [Hash] the Hash containing available inflection aliases
      # @overload aliases(kind)
      #   Gets inflection aliases and their pointers for the given +kind+.
      #   @param [Symbol] kind the kind of aliases to get
      #   @return [Hash] the Hash containing available inflection
      #     aliases for the given +kind+ and current locale
      # @overload aliases(kind, locale)
      #   Gets inflection aliases and their pointers for the given +kind+ and +locale+.
      #   @param [Symbol] kind the kind of aliases to get
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the Hash containing available inflection
      #     aliases for the given +kind+ and +locale+
      def aliases(kind=nil, locale=nil)
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        aliases = @inflection_aliases[locale]
        return {} if aliases.nil?
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases.merge(aliases){|k,v| v[:target]}
      end

      # Gets known inflection kinds.
      # 
      # @api public
      # @return [Array<Symbol>] the array containing known inflection kinds
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @overload available_inflection_kinds
      #   Gets known inflection kinds for the current locale.
      #   @return [Array<Symbol>] the array containing known inflection kinds
      # @overload available_inflection_kinds(locale)
      #   Gets known inflection kinds for the given +locale+.
      #   @param [Symbol] locale the locale for which operation has to be done
      #   @return [Array<Symbol>] the array containing known inflection kinds
      def kinds(locale=nil)
        locale  = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        kinds = @inflection_kinds[locale]
        return [] if kinds.nil?
        kinds.keys
      end
      alias_method :inflection_kinds, :kinds

      # Gets locales which have configured inflection support.
      # 
      # @api public
      # @see I18n::Inflector.locales Short name: I18n::Inflector.locales
      # @return [Array<Symbol>] the array containing locales that support inflection
      # @note If +kind+ is given it returns only these locales
      #   that are inflected and support inflection by this kind.
      def inflected_locales(kind=nil)
        I18n.backend.inflector_try_init_backend
        inflected_locales = (@inflection_tokens.keys || [])
        return inflected_locales if kind.to_s.empty?
        kind = kind.to_sym
        inflected_locales.select do |loc|
          kinds = @inflection_kinds[loc]
          !kinds.nil? && kinds[kind]
        end
      end
      alias_method :locales, :inflected_locales
      alias_method :supported_locales, :inflected_locales

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
        I18n.backend.inflector_try_init_backend
        @inflection_tokens.has_key?(locale)
      end
      alias_method :locale?, :inflected_locale?
      alias_method :locale_supported?, :inflected_locale?
      alias_method :supported_locale?, :inflected_locale?

      # Gets the description of the given inflection token.
      # 
      # @api public
      # @see I18n::Inflector.description Short name: I18n::Inflector.description
      # @note If the given +token+ is really an alias it
      #   returns the description of the true token that
      #   it points to.
      # @raise [I18n::InvalidLocale] if a used locale is invalid
      # @return [String,nil] the descriptive string or +nil+
      # @overload token_description(token)
      #   Uses current locale to get description of the given token.
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found)
      # @overload token_description(token, locale)
      #   Uses the given +locale+ to get description of the given inflection token.
      #   @param [Symbol] locale the locale to use
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found)
      def token_description(token, locale=nil)
        locale = inflector_prep_locale(locale)
        return nil if token.to_s.empty?
        I18n.backend.inflector_try_init_backend
        inflections = @inflection_tokens[locale]
        aliases     = @inflection_aliases[locale]
        return nil if (inflections.nil? || aliases.nil?)
        token = token.to_sym
        match = (inflections[token] || aliases[token])
        return nil if match.nil?
        match[:description]
      end
      alias_method :get_token_description, :token_description

      protected
  
      # @private
      def init_frontend(kinds, tokens, aliases, defaults)
        @inflection_kinds     = kinds
        @inflection_tokens    = tokens
        @inflection_aliases   = aliases
        @inflection_defaults  = defaults
      end

      # @private
      def tkl_args(args)
        token, kind, locale = case args.count
        when 1 then [args[0], nil, nil]
        when 2 then [args[0], nil, args[1]]
        when 3 then args
        else raise ArgumentError.new("wrong number of arguments: #{args.count} for (1..3)")
        end
        [token,kind,locale]
      end

    end

  end
end
