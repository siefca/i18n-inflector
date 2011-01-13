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
      # @raise [I18n::InvalidLocale] if there is no proper locale name
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
        kind, locale = inflector_prep_kl(kind, locale)
        return nil if kind.nil?
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return nil if idb.nil?
        idb.get_default_token(kind)
      end

      # Checks if the given +token+ is an alias.
      # 
      # @api public
      # @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @raise [ArgumentError] if the count of arguments is invalid
      # @overload has_alias?(token)
      #   Uses current locale to check if the given +token+ is an alias.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @overload has_alias?(token, locale)
      #   Uses the given +locale+ to check if the given +token+ is an alias.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @overload has_alias?(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to check if the given +token+ is an alias.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      def has_alias?(*args)
        token, kind, locale = tkl_args(args)
        return false if (!kind.nil? && kind.to_s.empty?)
        return false if token.nil?
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return false if idb.nil?
        r = idb.has_alias?(token)
        kind.nil? ? r : (r && idb.get_kind?(token) == kind)
      end
      alias_method :token_has_alias?, :has_alias?

      # Checks if the given +token+ is a true token (not alias).
      # 
      # @api public
      # @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
      # @raise [ArgumentError] if the count of arguments is invalid
      # @overload has_true_token?(token)
      #   Uses current locale to check if the given +token+ is a true token.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @overload has_true_token?(token, locale)
      #   Uses the given +locale+ to check if the given +token+ is a true token.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @overload has_true_token?(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to check if the given +token+ is a true token.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      def has_true_token?(*args)
        token, kind, locale = tkl_args(args)
        return false if (!kind.nil? && kind.to_s.empty?)
        return false if token.nil?
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return false if idb.nil?
        token = token.to_sym
        r = idb.has_true_token?(token)
        kind.nil? ? r : (r && idb.get_kind?(token) == kind)
      end
      alias_method :token_has_true?, :has_true_token?

       # Checks if the given +token+ exists. It may be an alias or a true token.
       # 
       # @api public
       # @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @raise [I18n::InvalidLocale] if the given +locale+ is invalid
       # @raise [ArgumentError] if the count of arguments is invalid
       # @overload has_token?(token)
       #   Uses current locale to check if the given +token+ is a token.
       #   @param [Symbol,String] token name of the checked token
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @overload has_token?(token, locale)
       #   Uses the given +locale+ to check if the given +token+ exists.
       #   @param [Symbol,String] token name of the checked token
       #   @param [Symbol] locale the locale to use
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @overload has_token?(token, kind, locale)
       #   Uses the given +locale+ and +kind+ to check if the given +token+ exists.
       #   @param [Symbol,String] token name of the checked token
       #   @param [Symbol] kind the kind used to narrow the check
       #   @param [Symbol] locale the locale to use
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       def has_token?(*args)
         token, kind, locale = tkl_args(args)
         return false if (!kind.nil? && kind.to_s.empty?)
         return false if token.nil?
         I18n.backend.inflector_try_init_backend
         idb = @idb[locale]
         return false if idb.nil?
         token = token.to_sym
         r = idb.has_token?(token)
         kind.nil? ? r : (r && idb.get_kind?(token) == kind)
       end
       alias_method :token_exists?, :has_token?

      # Gets true token for the given +token+ (which may be an alias).
      # 
      # @api public
      # @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #   the token is a real token or +nil+ otherwise
      # @raise [I18n::InvalidLocale] if there is no proper locale name
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
        idb = @idb[locale]
        return nil if idb.nil?
        idb.get_true_token(token.to_sym)
      end

      # Gets a kind for the given +token+ (which may be an alias).
      # 
      # @api public
      # @return [Symbol,nil] the kind of the given +token+ or +nil+
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @overload kind(token)
      #   Uses current locale to get a kind of the given +token+ (which may be an alias).
      #   @param [Symbol,String] token name of the token or alias
      #   @return [Symbol,nil] the kind of the given +token+
      #     for the current locale
      # @overload kind(token, locale)
      #   Uses the given +locale+ to get a kind of the given +token+ (which may be an alias).
      #   @param [Symbol,String] token name of the token or alias
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the kind of the given +token+
      #     for the given +locale+
      def kind(token, locale=nil)
        return nil if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return nil if idb.nil?
        idb.get_kind(token.to_sym)
      end

      # Gets available inflection tokens and their descriptions.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
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
        return {} if (!kind.nil? && kind.to_s.empty?)
        kind, locale = inflector_prep_kl(kind, locale)
        idb     = @idb[locale]
        return {} if idb.nil?
        idb.get_tokens(kind)
      end

      # Gets available inflection tokens and their values.
      # 
      # @api public
      # @return [Hash] the hash containing available inflection tokens and descriptions (or alias pointers)
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @note You may deduce whether the returned values are aliases or true tokens
      #   by testing if a value is a type of Symbol or String.
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
        return {} if (!kind.nil? && kind.to_s.empty?)
        kind, locale = inflector_prep_kl(kind, locale)
        idb = @idb[locale]
        return {} if idb.nil?
        idb.get_raw_tokens(kind)
      end
      alias_method :raw_tokens, :tokens_raw

      # Gets true inflection tokens and their values.
      # 
      # @api public
      # @return [Hash] the hash containing available inflection tokens and descriptions
      # @raise [I18n::InvalidLocale] if there is no proper locale name
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
        return {} if (!kind.nil? && kind.to_s.empty?)
        kind, locale = inflector_prep_kl(kind, locale)
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return {} if idb.nil?
        inflections = idb.get_true_tokens(kind)
      end
      alias_method :true_tokens, :tokens_true

      # Gets inflection aliases and their pointers.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
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
        return {} if (!kind.nil? && kind.to_s.empty?)
        kind, locale = inflector_prep_kl(kind, locale)
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return {} if idb.nil?
        idb.get_aliases(kind)
      end

      # Gets known inflection kinds.
      # 
      # @api public
      # @return [Array<Symbol>] the array containing known inflection kinds
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @overload kinds
      #   Gets known inflection kinds for the current locale.
      #   @return [Array<Symbol>] the array containing known inflection kinds
      # @overload kinds(locale)
      #   Gets known inflection kinds for the given +locale+.
      #   @param [Symbol] locale the locale for which operation has to be done
      #   @return [Array<Symbol>] the array containing known inflection kinds
      def kinds(locale=nil)
        locale = inflector_prep_locale(locale)
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return [] if idb.nil?
        idb.get_kinds
      end
      alias_method :inflection_kinds, :kinds

      # Tests if a kind exists.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [Boolean] +true+ if the given +kind+ exists, +false+ otherwise
      # @overload has_kind?(kind)
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +kind+ exists for the current
      #     locale, +false+ otherwise
      # @overload has_kind?(kind, locale)
      #   @param [Symbol] kind the identifier of a kind
      #   @param [Symbol] locale the locale identifier
      #   @return [Boolean] +true+ if the given +kind+ exists, +false+ otherwise
      def has_kind?(kind, locale=nil)
        return false if (!kind.nil? && kind.to_s.empty?)
        kind, locale = inflector_prep_kl(kind, locale)
        I18n.backend.inflector_try_init_backend
        @idb[locale].has_kind?(kind)
      end

      # Gets locales which have configured inflection support.
      # 
      # @api public
      # @return [Array<Symbol>] the array containing locales that support inflection
      # @note If +kind+ is given it returns only these locales
      #   that are inflected and support inflection by this kind.
      def inflected_locales(kind=nil)
        return [] if (!kind.nil? && kind.to_s.empty?)
        I18n.backend.inflector_try_init_backend
        inflected_locales = (@idb.keys || [])
        return inflected_locales if kind.nil?
        kind = kind.to_sym
        inflected_locales.reject{|l| @idb[l].nil? || !@idb[l].has_kind?(kind)}
      end
      alias_method :locales, :inflected_locales
      alias_method :supported_locales, :inflected_locales

      # Checks if the given locale was configured to support inflection.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [Boolean] +true+ if a locale supports inflection
      # @overload inflected_locale?(locale)
      #   Checks if the given locale was configured to support inflection.
      #   @param [Symbol] locale the locale to test
      #   @return [Boolean] +true+ if the given locale supports inflection
      # @overload inflected_locale?
      #   Checks if the current locale was configured to support inflection.
      #   @return [Boolean] +true+ if the current locale supports inflection
      def inflected_locale?(locale=nil)
        locale = inflector_prep_locale(locale) rescue false
        return false if locale.nil?
        I18n.backend.inflector_try_init_backend
        not @idb[locale].nil?
      end
      alias_method :locale?, :inflected_locale?
      alias_method :locale_supported?, :inflected_locale?
      alias_method :supported_locale?, :inflected_locale?

      # Gets the description of the given inflection token.
      # 
      # @api public
      # @note If the given +token+ is really an alias it
      #   returns the description of the true token that
      #   it points to.
      # @raise [I18n::InvalidLocale] if there is no proper locale name
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
        return nil if token.to_s.empty?
        locale = inflector_prep_locale(locale)
        return nil if token.to_s.empty?
        I18n.backend.inflector_try_init_backend
        idb = @idb[locale]
        return nil if idb.nil?
        idb.get_description(token.to_sym)
      end

      protected
  
      # This method initializes internal instance variable which is
      # kind of {I18n::Inflector::InflectionData} that allows accessing
      # inflection data loaded by backend. It's used by {I18n::Inflector::Backend}
      # methods to create a bridge to {I18n::Inflector}.
      # 
      # @return [void]
      # @param [InflectionData] idb inflection data from backend
      def init_frontend(idb)
        @idb = idb
      end

    end

  end
end
