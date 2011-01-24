# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains {I18n::Inflector::API} class,
# which is public API for I18n Inflector.

module I18n
  module Inflector

    # Instance of this class, the inflector, is attached
    # to I18n backend. This class contains common operations
    # that can be performed on inflections. It can operate
    # on both unnamed an named patterns (regular and strict kinds).
    # 
    # It uses the databases containing instances of
    # ({I18n::Inflector::InflectionData} and {I18n::Inflector::InflectionData_Strict})
    # keeped in the Hashes that are indexed by locale names.
    # 
    # It is also used by backend methods
    # to interpolate strings and load databases.
    # 
    # ==== Usage
    # You can access the instance of this class attached to
    # default I18n backend by calling:
    #   I18n.backend.inflector
    # or in a short form:
    #   I18n.inflector
    # In case of named patterns:
    #   I18n.inflector.named
    # 
    # @see I18n::Inflector::API_Named The API_Named class
    #   for accessing inflection data for named
    #   patterns (strict kinds).
    # @api public
    class API < API_Named

      # Options controlling the engine.
      # 
      # @api public
      # @return [I18n::Inflector::InflectionOptions] the set of options
      #   controlling inflection engine
      # @see I18n::Inflector::InflectionOptions#raises
      # @see I18n::Inflector::InflectionOptions#unknown_defaults
      # @see I18n::Inflector::InflectionOptions#excluded_defaults
      # @see I18n::Inflector::InflectionOptions#aliased_patterns
      # @example Usage of +options+:
      #   # globally set raises flag
      #   I18n.inflector.options.raises = true
      #   
      #   # globally set raises flag (the same meaning as the example above)
      #   I18n.backend.inflector.options.raises = true
      #   
      #   # set raises flag just for this translation
      #   I18n.translate('welcome', :inflector_raises => true)
      attr_reader :options

      # This reader allows to reach a reference to the
      # object that is a kind of {I18n::Inflector::API_Named}
      # and handles inflections for named patterns (strict kinds).
      # 
      # @api public
      def named
        @named ||= I18n::Inflector::API_Named.new(@idb_strict, @options)
      end

      # Initilizes the inflector by creating internal databases
      # used for storing inflection data and options.
      # 
      # @api public
      def initialize
        super(nil, nil)
        @idb_strict = {}
      end

      # Creates a database for the specified locale.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @param [Symbol] locale the locale for which the inflections database is to be created
      # @return [I18n::Inflector::InflectionData] the new object for keeping inflection data
      #   for the given +locale+
      def new_database(locale)
        locale = prep_locale(locale)
        @idb[locale] = I18n::Inflector::InflectionData.new(locale)
      end

      # Creates internal databases for the specified locale.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @param [Symbol] locale the locale for which the inflections databases are to be created
      # @return [Array<I18n::Inflector::InflectionData,I18n::Inflector::InflectionData_Strict>] the
      #   array of objects for keeping inflection data for the given +locale+
      def new_databases(locale)
        normal = new_databases(locale)
        strict = named.new_database(locale)
        [normal, strict]
      end

      # Attaches {I18n::Inflector::InflectionData} and
      # optionally {I18n::Inflector::InflectionData_Strit} instance
      # to the inflector.
      #
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @note It doesn't create copy of inflection data, it registers the given object(s).
      # @overload add_database(db)
      #   @param [I18n::Inflector::InflectionData] db inflection data to add
      #   @return [I18n::Inflector::InflectionData] the given object or +nil+
      #     if something went wrong (e.g. +nil+ was given as an argument)
      # @overload add_database(db, db_strict)
      #   @note An array is returned and databases are
      #     used only if both databases are successfully attached. References to
      #     both databases will be set to +nil+ if there would be a problem with attaching
      #     any of them.
      #   @param [I18n::Inflector::InflectionData] db inflection data to add
      #   @param [I18n::Inflector::InflectionData_Strict] db_strict strict inflection data to add
      #   @return [Array<I18n::Inflector::InflectionData,I18n::Inflector::InflectionData_Strict>] the
      #     array of the given objects or +nil+ if something went wrong (e.g. +nil+ was
      #     given as a first argument)
      def add_database(db, db_strict=nil)
        r = super(db)
        return r if (r.nil? || db_strict.nil?)
        r_strict = named.add_database(db_strict)
        if r_strict.nil?
          delete_database(db.locale)
          return nil
        end
        [r, r_strict]
      end
      alias_method :add_databases, :add_database

      # Deletes the internal databases for the specified locale.
      # 
      # @api public
      # @note It detaches the databases from {I18n::Inflector::API} instance.
      #   Other objects referring to them may still use it.
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @param [Symbol] locale the locale for which the inflections database is to be deleted.
      # @return [void]
      def delete_databases(locale)
        delete_database(locale)
        named.delete_database(locale)
      end

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
        super || named.inflected_locale?(locale)
      end
      alias_method :locale?,            :inflected_locale?
      alias_method :locale_supported?,  :inflected_locale?

      # Gets locales which have configured inflection support.
      # 
      # @api public
      # @return [Array<Symbol>] the array containing locales that support inflection
      # @note If +kind+ is given it returns only these locales
      #   that support inflection by this kind. It also calls the same method from
      #   attached database containing strict kinds.
      def inflected_locales(kind=nil)
        if kind.to_s[0..0] == I18n::Inflector::NAMED_MARKER
          named.inflected_locales(kind.to_s[1..-1])
        else
          (super + named.inflected_locales(kind)).uniq
        end
      end

      # Tests if a regular (or strict) kind exists.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [Boolean] +true+ if the given +kind+ exists, +false+ otherwise
      # @overload has_kind?(kind)
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +kind+ exists for the current
      #     locale, +false+ otherwise
      # @overload has_kind?(kind, locale)
      #   @param [Symbol,String] kind the identifier of a kind
      #   @param [Symbol] locale the locale identifier
      #   @return [Boolean] +true+ if the given +kind+ exists, +false+ otherwise
      def has_kind?(kind, locale=nil)
        if kind.to_s[0..0] == I18n::Inflector::NAMED_MARKER
          return named.has_kind?(kind.to_s[1..-1], locale)
        end
        super
      end

      # Reads default token for the given +kind+.
      # 
      # @api public
      # @return [Symbol,nil] the default token for the given kind or +nil+
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @overload default_token(kind)
      #   This method reads default token for the given +kind+ and current locale.
      #   @param [Symbol,String] kind the kind of tokens
      #   @return [Symbol,nil] the default token for the given kind or +nil+ if
      #     there is no default token
      # @overload default_token(kind, locale)
      #   This method reads default token for the given +kind+ and the given +locale+.
      #   @param [Symbol,String] kind the kind of tokens
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the default token for the given kind or +nil+ if
      #     there is no default token
      def default_token(kind, locale=nil)
        return nil if kind.to_s.empty?
        if kind.to_s[0..0] == I18n::Inflector::NAMED_MARKER
          return named.default_token(kind.to_s[1..-1], locale)
        end
        super
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
      #   @param [Symbol,String] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      def has_alias?(*args)
        token, kind, locale = tkl_args(args)
        return false if token.to_s.empty?
        unless kind.nil?
          kind = kind.to_s
          reutrn false if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.has_alias?(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).has_alias?(token.to_sym, kind)
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
      #   @param [Symbol,String] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      def has_true_token?(*args)
        token, kind, locale = tkl_args(args)
        return false if token.to_s.empty?
        unless kind.nil?
          kind = kind.to_s
          return false if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.has_true_token?(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).has_true_token?(token.to_sym, kind)
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
       #   @param [Symbol,String] kind the kind used to narrow the check
       #   @param [Symbol] locale the locale to use
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       def has_token?(*args)
         token, kind, locale = tkl_args(args)
         return false if token.to_s.empty?
         unless kind.nil?
           kind = kind.to_s
           return false if kind.empty?
           if kind[0..0] == I18n::Inflector::NAMED_MARKER
             return named.has_token?(token, kind[1..-1], locale)
           end
           kind = kind.to_sym
         end
         data_safe(locale).has_token?(token.to_sym, kind)
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
      # @overload true_token(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to get a real token for the given +token+.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the true token if the given +token+ is an alias, token if
      #     the token is a real token or +nil+ otherwise
      def true_token(*args)
        token, kind, locale = tkl_args(args)
        return nil if token.to_s.empty?
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.true_token(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_true_token(token.to_sym, kind)
      end
      alias_method :resolve_alias, :true_token

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
      def kind(*args)
        token, kind, locale = tkl_args(args)
        return nil if token.to_s.empty?
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.kind(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_kind(token.to_sym, kind)
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
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale.
      # @overload tokens(kind, locale)
      #   Gets available inflection tokens and their descriptions for some +kind+ and +locale+.
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale
      def tokens(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return {} if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.tokens(kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_tokens(kind)
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
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+. In case of
      #     aliases the returned values are Symbols
      # @overload tokens_raw(kind, locale)
      #   Gets available inflection tokens and their values for the given +kind+ and +locale+.
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+ and +locale+.
      #     In case of aliases the returned values are Symbols
      def tokens_raw(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return {} if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.tokens_raw(kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_raw_tokens(kind)
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
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+
      # @overload tokens_true(kind, locale)
      #   Gets true inflection tokens and their values for the given +kind+ and +value+.
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values for the given +kind+ and +locale+
      def tokens_true(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return {} if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.tokens_true(kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_true_tokens(kind)
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
      #   @param [Symbol,String] kind the kind of aliases to get
      #   @return [Hash] the Hash containing available inflection
      #     aliases for the given +kind+ and current locale
      # @overload aliases(kind, locale)
      #   Gets inflection aliases and their pointers for the given +kind+ and +locale+.
      #   @param [Symbol,String] kind the kind of aliases to get
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the Hash containing available inflection
      #     aliases for the given +kind+ and +locale+
      def aliases(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.aliases(kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_aliases(kind)
      end

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
      #     went wrong (e.g. token was not found or +kind+ mismatched)
      def token_description(*args)
        token, kind, locale = tkl_args(args)
        return nil if token.to_s.empty?
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == I18n::Inflector::NAMED_MARKER
            return named.token_description(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_description(token.to_sym, kind)
      end

      # Interpolates inflection values in a given +string+
      # using kinds given in +options+ and a matching tokens.
      # 
      # @param [String] string the translation string
      #  containing patterns to interpolate
      # @param [String,Symbol] locale the locale identifier 
      # @param [Hash] options the options
      # @option options [Boolean] :inflector_excluded_defaults (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#excluded_defaults})
      # @option options [Boolean] :inflector_unknown_defaults (true) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#unknown_defaults})
      # @option options [Boolean] :inflector_raises (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#raises})
      # @option options [Boolean] :inflector_aliased_patterns (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#aliased_patterns})
      # @return [String] the string with interpolated patterns
      def interpolate(string, locale, options = {})
        used_kinds        = options.except(*I18n::Inflector::INFLECTOR_RESERVED_KEYS)
        sw, op            = @options, options
        raises            = (s=op.delete :inflector_raises).nil?            ? sw.raises            : s
        aliased_patterns  = (s=op.delete :inflector_aliased_patterns).nil?  ? sw.aliased_patterns  : s
        unknown_defaults  = (s=op.delete :inflector_unknown_defaults).nil?  ? sw.unknown_defaults  : s
        excluded_defaults = (s=op.delete :inflector_excluded_defaults).nil? ? sw.excluded_defaults : s

        idb               = @idb[locale]
        idb_strict        = @idb_strict[locale]

        string.gsub(I18n::Inflector::PATTERN) do
          pattern_fix     = $1
          strict_kind     = $2
          pattern_content = $3
          ext_pattern     = $&
          parsed_kind     = nil
          default_token   = nil
          ext_value       = nil
          ext_freetext    = ''
          found           = false
          subdb           = idb
          parsed_default_v= nil

          # leave escaped pattern as is
          next ext_pattern[1..-1] if I18n::Inflector::ESCAPES.has_key?(pattern_fix)

          # set parsed kind if strict kind is given (named pattern is parsed)
          strict_kind = nil if (!strict_kind.nil? && strict_kind.empty?)

          unless strict_kind.nil?
            strict_kind   = strict_kind.to_sym
            parsed_kind   = strict_kind
            subdb         = idb_strict
            default_token = subdb.get_default_token(parsed_kind)
          end

          # process pattern content's
          pattern_content.scan(I18n::Inflector::TOKENS) do
            ext_token     = $1.to_s
            ext_value     = $2.to_s
            ext_freetext  = $3.to_s
            tokens        = Hash.new(false)
            negatives     = Hash.new(false)
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

            # split tokens if comma is present and put into fast list
            ext_token.split(I18n::Inflector::OPERATOR_MULTI).each do |t|
              # token name corrupted
              if t.empty?
                raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                next
              end

              # mark negative-matching tokens and put them to negatives fast list
              if t[0..0] == I18n::Inflector::OPERATOR_NOT
                t = t[1..-1]
                if t.empty?
                  raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                  next
                end
                t = t.to_sym
                t = subdb.get_true_token(t, strict_kind) if aliased_patterns
                negatives[t] = true
              end

              t = t.to_sym
              t = subdb.get_true_token(t, strict_kind) if aliased_patterns

              # get kind for that token
              kind  = subdb.get_kind(t, strict_kind)
              if kind.nil?
                raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                next
              end

              # set processed kind after matching first token in a pattern
              if parsed_kind.nil?
                parsed_kind   = kind
                default_token = subdb.get_default_token(parsed_kind)
              elsif parsed_kind != kind
                # different kinds in one pattern are prohibited
                raise I18n::MisplacedInflectionToken.new(ext_pattern, t, parsed_kind) if raises
                next
              end

              # use that token
              tokens[t] = true unless negatives[t]
            end

            # self-explanatory
            if (tokens.empty? && negatives.empty?)
              raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
            end

            # fetch the kind's option or fetch default if an option does not exists
            option = options.has_key?(kind) ? options[kind] : default_token

            if option.to_s.empty?
              # if option is given but is unknown, empty or nil
              # then use default option for a kind if unknown_defaults is switched on
              option = unknown_defaults ? default_token : nil
            else
              # validate option and if it's unknown try in aliases
              option = subdb.get_true_token(option.to_sym, strict_kind)

              # if still nothing then fall back to default value
              # for a kind in unknown_defaults switch is on
              if option.nil?
                option = unknown_defaults ? default_token : nil
              end
            end

            # if the option is still unknown
            if option.nil?
              raise I18n::InvalidOptionForKind.new(ext_pattern, kind, ext_token, nil) if raises
              next
            end

            # memorize default value for further processing
            # outside this block if excluded_defaults switch is on
            parsed_default_v = ext_value if (excluded_defaults && !default_token.nil?)

            # throw the value if a given option matches one of the tokens from group
            # or negatively matches one of the negated tokens
            case negatives.count
            when 0 then next unless tokens[option]
            when 1 then next if  negatives[option]
            end

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
            # and a correct token was found in an inflection option but
            # has not been found in a pattern then interpolate
            # the pattern with a value picked for the default
            # token for that kind if a default token was present
            # in a pattern
            kind    = nil
            token   = options[parsed_kind]
            kind    = subdb.get_kind(token)
            result  = parsed_default_v unless kind.nil?
          end

          pattern_fix + (result || ext_freetext)

        end # single pattern processing

      end

      protected

      # @private
      def data(locale=nil)
        @idb[prep_locale(locale)]
      end

      # @private
      def data_safe(locale=nil)
        @idb[prep_locale(locale)] || I18n::Inflector::InflectionData.new(locale)
      end

      # This method is the internal helper that prepares arguments
      # containing +token+, +kind+ and +locale+.
      # 
      # @note This method leaves +kind+ as is when it's +nil+ or empty. It sets
      #   +token+ to +nil+ when it's empty.
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @raise [ArgumentError] if the count of arguments is invalid
      # @return [Array<Symbol,Symbol,Symbol>] the array containing
      #   cleaned and validated +token+, +kind+ and +locale+
      # @overload tkl_args(token, kind, locale)
      #   Prepares arguments containing +token+, +kind+ and +locale+.
      #   @param [String,Hash] token the token
      #   @param [String,Hash] kind the inflection kind
      #   @param [String,Hash] locale the locale identifier
      #   @return [Array<Symbol,Symbol,Symbol>] the array containing
      #     cleaned and validated +token+, +kind+ and +locale+
      # @overload tkl_args(token, locale)
      #   Prepares arguments containing +token+ and +locale+.
      #   @param [String,Hash] token the token
      #   @param [String,Hash] locale the locale identifier
      #   @return [Array<Symbol,Symbol,Symbol>] the array containing
      #     cleaned and validated +token+, +kind+ and +locale+
      def tkl_args(args)
        token, kind, locale = case args.count
        when 1 then [args[0], nil, nil]
        when 2 then args[1].to_s[0..0] == I18n::Inflector::NAMED_MARKER ? [args[0], args[1], nil] : [args[0], nil, args[1]]
        when 3 then args
        else raise ArgumentError.new("wrong number of arguments: #{args.count} for (1..3)")
        end
        [token,kind,locale]
      end

    end # class API

  end # module Inflector
end # module I18n
