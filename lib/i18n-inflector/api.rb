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
    # This class is used by backend methods to interpolate
    # strings and load inflections.
    # 
    # It uses the databases containing instances of
    # {I18n::Inflector::InflectionData} and {I18n::Inflector::InflectionData_Strict}
    # that are stored in the Hashes and indexed by locale names.
    # 
    # Note that strict kinds used to handle named patterns
    # internally are stored in a different database than
    # regular kinds. Most of the methods of this class are also
    # aware of strict kinds and will call proper methods handling
    # strict inflection data when the +@+ symbol is detected
    # at the beginning of the given identifier of a kind.
    # 
    # ==== Usage
    # You can access the instance of this class attached to
    # default I18n backend by calling:
    #   I18n.backend.inflector
    # or in a short form:
    #   I18n.inflector
    # In case of named patterns (strict kinds):
    #   I18n.inflector.strict
    # 
    # @see I18n::Inflector::API_Strict The API_Strict class
    #   for accessing inflection data for named
    #   patterns (strict kinds).
    # @see file:EXAMPLES The examples of real-life usage.
    # @api public
    class API < API_Strict

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

      # @private
      def strict
        @strict ||= I18n::Inflector::API_Strict.new(@idb_strict, @options)
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
      def new_database(locale)
        locale = prep_locale(locale)
        @idb[locale] = I18n::Inflector::InflectionData.new(locale)
      end

      # Creates internal databases (regular and strict) for the specified locale.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @param [Symbol] locale the locale for which the inflections databases are to be created
      # @return [Array<I18n::Inflector::InflectionData,I18n::Inflector::InflectionData_Strict>] the
      #   array of objects for keeping inflection data
      def new_databases(locale)
        normal = new_databases(locale)
        strict = strict.new_database(locale)
        [normal, strict]
      end

      # Attaches instance of {I18n::Inflector::InflectionData} and
      # optionally {I18n::Inflector::InflectionData_Strict}
      # to the inflector.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @note It doesn't create a copy of inflection data, but registers the given object(s).
      # @return [I18n::Inflector::InflectionData,Array,nil] 
      # @overload add_database(db)
      #   @param [I18n::Inflector::InflectionData] db inflection data to add
      #   @return [I18n::Inflector::InflectionData,nil] the given object or +nil+
      #     if something went wrong (e.g. +nil+ was given as an argument)
      # @overload add_database(db, db_strict)
      #   @note An array is returned and databases are
      #     used only if both databases are successfully attached. References to
      #     both databases will be unset if there would be a problem with attaching
      #     any of them.
      #   @param [I18n::Inflector::InflectionData] db inflection data to add
      #   @param [I18n::Inflector::InflectionData_Strict] db_strict strict inflection data to add
      #   @return [Array<I18n::Inflector::InflectionData,I18n::Inflector::InflectionData_Strict>,nil] the
      #     array of the given objects or +nil+ if something went wrong (e.g. +nil+ was
      #     given as the first argument)
      def add_database(db, db_strict=nil)
        r = super(db)
        return r if (r.nil? || db_strict.nil?)
        r_strict = strict.add_database(db_strict)
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
        strict.delete_database(locale)
      end

      # Checks if the given locale was configured to support inflection.
      # 
      # @api public
      # @note That method uses information from regular and strict kinds.
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
        super || strict.inflected_locale?(locale)
      end
      alias_method :locale?,            :inflected_locale?
      alias_method :locale_supported?,  :inflected_locale?

      # Gets locales which have configured inflection support.
      # 
      # @api public
      # @note That method uses information from regular and strict kinds.
      # @return [Array<Symbol>] the array containing locales that support inflection
      # 
      # @overload inflected_locales
      #   Gets locales which have configured inflection support.
      #   @return [Array<Symbol>] the array containing locales that support inflection
      # @overload inflected_locales(kind)
      #   Gets locales which have configured inflection support for the given +kind+.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Array<Symbol>] the array containing locales that support inflection
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#inflected_locales})
      def inflected_locales(kind=nil)
        if kind.to_s[0..0] == NAMED_MARKER
          strict.inflected_locales(kind.to_s[1..-1])
        else
          (super + strict.inflected_locales(kind)).uniq
        end
      end

      # Tests if a kind exists.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [Boolean] +true+ if the given +kind+ exists, +false+ otherwise
      # @note If +kind+ begins with the +@+ symbol then the variant of this method
      #   operating on strict kinds will be called ({I18n::Inflector::API_Strict#has_kind?})
      # @overload has_kind?(kind)
      #   Tests if a regular kind exists for the current locale.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +kind+ exists for the current
      #     locale, +false+ otherwise
      # @overload has_kind?(kind, locale)
      #   Tests if a regular kind exists for the given +locale+.
      #   @param [Symbol,String] kind the identifier of a kind
      #   @param [Symbol] locale the locale identifier
      #   @return [Boolean] +true+ if the given +kind+ exists, +false+ otherwise
      def has_kind?(kind, locale=nil)
        if kind.to_s[0..0] == NAMED_MARKER
          return strict.has_kind?(kind.to_s[1..-1], locale)
        end
        super
      end

      # Reads default token for the given +kind+.
      # 
      # @api public
      # @return [Symbol,nil] the default token or +nil+
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @note If +kind+ begins with the +@+ symbol then the variant of this method
      #   operating on strict kinds will be called ({I18n::Inflector::API_Strict#default_token})
      # @overload default_token(kind)
      #   This method reads default token for the given +kind+ and the current locale.
      #   @param [Symbol,String] kind the kind of tokens
      #   @return [Symbol,nil] the default token or +nil+ if
      #     there is no default token
      # @overload default_token(kind, locale)
      #   This method reads default token for the given +kind+ and the given +locale+.
      #   @param [Symbol,String] kind the kind of tokens
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the default token or +nil+ if
      #     there is no default token
      def default_token(kind, locale=nil)
        return nil if (kind.nil? || kind.to_s.empty?)
        if kind.to_s[0..0] == NAMED_MARKER
          return strict.default_token(kind.to_s[1..-1], locale)
        end
        super
      end

      # Checks if the given +token+ is an alias.
      # 
      # @api public
      # @note By default it uses regular kinds database, not strict kinds.
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
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#has_alias?})
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      # @overload has_alias?(token, strict_kind)
      #   Uses the current locale and the given +strict_kind+ (which name must begin with
      #   the +@+ symbol) to check if the given +token+ is an alias.
      #   @note It calls {I18n::Inflector::API_Strict#has_alias?} on strict kinds data.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] strict_kind the kind of the given alias
      #   @return [Boolean] +true+ if the given +token+ is an alias, +false+ otherwise
      def has_alias?(*args)
        token, kind, locale = tkl_args(args)
        return false if (token.nil? || token.to_s.empty?)
        unless kind.nil?
          kind = kind.to_s
          reutrn false if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.has_alias?(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).has_alias?(token.to_sym, kind)
      end
      alias_method :token_has_alias?, :has_alias?

      # Checks if the given +token+ is a true token (not alias).
      # 
      # @api public
      # @note By default it uses regular kinds database, not strict kinds.
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
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#has_true_token?})
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] kind the kind used to narrow the check
      #   @param [Symbol] locale the locale to use
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      # @overload has_true_token?(token, strict_kind)
      #   Uses the current locale and the given +strict_kind+ (which name must begin with
      #   the +@+ symbol) to check if the given +token+ is a true token.
      #   @note It calls {I18n::Inflector::API_Strict#has_true_token?} on strict kinds data.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] strict_kind the kind of the given token
      #   @return [Boolean] +true+ if the given +token+ is a true token, +false+ otherwise
      def has_true_token?(*args)
        token, kind, locale = tkl_args(args)
        return false if (token.nil? || token.to_s.empty?)
        unless kind.nil?
          kind = kind.to_s
          return false if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.has_true_token?(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).has_true_token?(token.to_sym, kind)
      end
      alias_method :token_has_true?, :has_true_token?

       # Checks if the given +token+ exists. It may be an alias or a true token.
       # 
       # @api public
       # @note By default it uses regular kinds database, not strict kinds.
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
       #   @note If +kind+ begins with the +@+ symbol then the variant of this method
       #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#has_token?})
       #   @param [Symbol,String] token name of the checked token
       #   @param [Symbol,String] kind the kind used to narrow the check
       #   @param [Symbol] locale the locale to use
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       # @overload has_token?(token, strict_kind)
       #   Uses the current locale and the given +strict_kind+ (which name must begin with
       #   the +@+ symbol) to check if the given +token+ exists.
       #   @note It calls {I18n::Inflector::API_Strict#has_token?} on strict kinds data.
       #   @param [Symbol,String] token name of the checked token
       #   @param [Symbol,String] strict_kind the kind of the given token
       #   @return [Boolean] +true+ if the given +token+ exists, +false+ otherwise
       def has_token?(*args)
         token, kind, locale = tkl_args(args)
         return false if (token.nil? || token.to_s.empty?)
         unless kind.nil?
           kind = kind.to_s
           return false if kind.empty?
           if kind[0..0] == NAMED_MARKER
             return strict.has_token?(token, kind[1..-1], locale)
           end
           kind = kind.to_sym
         end
         data_safe(locale).has_token?(token.to_sym, kind)
       end
       alias_method :token_exists?, :has_token?

      # Gets true token for the given +token+. If the token
      # is an alias it will be resolved
      # and a true token (target) will be returned.
      # @note By default it uses regular kinds database, not strict kinds.
      # @api public
      # @return [Symbol,nil] the true token or +nil+
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @overload true_token(token)
      #   Uses current locale to get a real token for the given +token+.
      #   @param [Symbol,String] token name of the checked token
      #   @return [Symbol,nil] the true token or +nil+
      # @overload true_token(token, locale)
      #   Uses the given +locale+ to get a real token for the given +token+.
      #   If the token is an alias it will be resolved
      #   and a true token (target) will be returned.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the true token or +nil+
      # @overload true_token(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to get a real token for the given +token+.
      #   If the token is an alias it will be resolved
      #   and a true token (target) will be returned.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#true_token})
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] kind the kind of the given token
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the true token or +nil+
      # @overload true_token(token, strict_kind)
      #   Uses the current locale and the given +strict_kind+ (which name must begin with
      #   the +@+ symbol) to get a real token for the given +token+.
      #   @note It calls {I18n::Inflector::API_Strict#true_token} on strict kinds data.
      #   @param [Symbol,String] token name of the checked token
      #   @param [Symbol,String] strict_kind the kind of the given token
      #   @return [Symbol,nil] the true token
      def true_token(*args)
        token, kind, locale = tkl_args(args)
        return nil if (token.nil? || token.to_s.empty?)
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.true_token(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_true_token(token.to_sym, kind)
      end
      alias_method :resolve_alias, :true_token

      # Gets a kind for the given +token+ (which may be an alias).
      # 
      # @api public
      # @note By default it uses regular kinds database, not strict kinds.
      # @return [Symbol,nil] the kind of the given +token+ or +nil+
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @overload kind(token)
      #   Uses the current locale to get a kind of the given +token+ (which may be an alias).
      #   @param [Symbol,String] token name of the token or alias
      #   @return [Symbol,nil] the kind of the given +token+
      # @overload kind(token, locale)
      #   Uses the given +locale+ to get a kind of the given +token+ (which may be an alias).
      #   @param [Symbol,String] token name of the token or alias
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the kind of the given +token+
      # @overload kind(token, kind, locale)
      #   Uses the given +locale+ to get a kind of the given +token+ (which may be an alias).
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#kind})
      #   @param [Symbol,String] token name of the token or alias
      #   @param [Symbol,String] kind the kind name to narrow the search
      #   @param [Symbol] locale the locale to use
      #   @return [Symbol,nil] the kind of the given +token+
      # @overload kind(token, strict_kind)
      #   Uses the current locale and the given +strict_kind+ (which name must begin with
      #   the +@+ symbol) to get a kind of the given +token+ (which may be an alias).
      #   @note It calls {I18n::Inflector::API_Strict#kind} on strict kinds data.
      #   @param [Symbol,String] token name of the token or alias
      #   @param [Symbol,String] kind the kind of the given token
      #   @return [Symbol,nil] the kind of the given +token+
      def kind(*args)
        token, kind, locale = tkl_args(args)
        return nil if (token.nil? || token.to_s.empty?)
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.kind(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_kind(token.to_sym, kind)
      end

      # Gets available inflection tokens and their descriptions.
      # 
      # @api public
      # @note By default it uses regular kinds database, not strict kinds.
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [Hash] the hash containing available inflection tokens and descriptions
      # @note You cannot deduce where aliases are pointing to, since the information
      #   about a target is replaced by the description. To get targets use the
      #   {#raw_tokens} method. To simply list aliases and their targets use
      #   the {#aliases} method.
      # @overload tokens
      #   Gets available inflection tokens and their descriptions.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases,
      #     for all kinds.
      # @overload tokens(kind)
      #   Gets available inflection tokens and their descriptions for some +kind+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#tokens})
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale.
      # @overload tokens(kind, locale)
      #   Gets available inflection tokens and their descriptions for some +kind+ and +locale+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#tokens})
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values, including aliases, for current locale
      def tokens(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return {} if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.tokens(kind[1..-1], locale)
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
      #   Gets available inflection tokens and their values for regular kinds.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values. In case of aliases the returned
      #     values are Symbols
      # @overload tokens_raw(kind)
      #   Gets available inflection tokens and their values for the given +kind+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#tokens_raw})
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values. In case of aliases the returned
      #     values are Symbols
      # @overload tokens_raw(kind, locale)
      #   Gets available inflection tokens and their values for the given +kind+ and +locale+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#tokens_raw})
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values. In case of aliases the returned
      #     values are Symbols
      def tokens_raw(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return {} if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.tokens_raw(kind[1..-1], locale)
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
      #   Gets true inflection tokens and their values for regular kinds.
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values
      # @overload tokens_true(kind)
      #   Gets true inflection tokens and their values for the given +kind+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#tokens_true})
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values
      # @overload tokens_true(kind, locale)
      #   Gets true inflection tokens and their values for the given +kind+ and +value+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#tokens_true})
      #   @param [Symbol,String] kind the kind of inflection tokens to be returned
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the hash containing available inflection tokens as keys
      #     and their descriptions as values
      def tokens_true(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return {} if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.tokens_true(kind[1..-1], locale)
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
      #   Gets inflection aliases and their pointers for regular kinds.
      #   @return [Hash] the Hash containing available inflection aliases
      # @overload aliases(kind)
      #   Gets inflection aliases and their pointers for the given +kind+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#aliases})
      #   @param [Symbol,String] kind the kind of aliases to get
      #   @return [Hash] the Hash containing available inflection aliases
      # @overload aliases(kind, locale)
      #   Gets inflection aliases and their pointers for the given +kind+ and +locale+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#aliases})
      #   @param [Symbol,String] kind the kind of aliases to get
      #   @param [Symbol] locale the locale to use
      #   @return [Hash] the Hash containing available inflection aliases
      def aliases(kind=nil, locale=nil)
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.aliases(kind[1..-1], locale)
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
      #   it points to. By default it uses regular kinds database,
      #   not strict kinds.
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @return [String,nil] the descriptive string or +nil+
      # @overload token_description(token)
      #   Uses current locale to get description of the given inflection +token+.
      #   @param [Symbol] token the identifier of a token
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found)
      # @overload token_description(token, locale)
      #   Uses the given +locale+ to get description of the given inflection +token+.
      #   @param [Symbol,String] token the identifier of a token
      #   @param [Symbol] locale the locale to use
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found)
      # @overload token_description(token, kind, locale)
      #   Uses the given +locale+ and +kind+ to get description of the given inflection +token+.
      #   @note If +kind+ begins with the +@+ symbol then the variant of this method
      #     operating on strict kinds will be called ({I18n::Inflector::API_Strict#token_description})
      #   @param [Symbol,String] token the identifier of a token
      #   @param [Symbol,String] kind the kind to narrow the results
      #   @param [Symbol] locale the locale to use
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found or +kind+ mismatched)
      # @overload token_description(token, strict_kind)
      #   Uses the default locale and the given +kind+ (which name must begin with
      #   the +@+ symbol) to get description of the given inflection +token+.
      #   @note It calls {I18n::Inflector::API_Strict#token_description} on strict kinds data.
      #   @param [Symbol,String] token the identifier of a token
      #   @param [Symbol,String] strict_kind the kind of a token
      #   @param [Symbol] locale the locale to use
      #   @return [String,nil] the descriptive string or +nil+ if something
      #     went wrong (e.g. token was not found or +kind+ mismatched)
      def token_description(*args)
        token, kind, locale = tkl_args(args)
        return nil if (token.nil? || token.to_s.empty?)
        unless kind.nil?
          kind = kind.to_s
          return nil if kind.empty?
          if kind[0..0] == NAMED_MARKER
            return strict.token_description(token, kind[1..-1], locale)
          end
          kind = kind.to_sym
        end
        data_safe(locale).get_description(token.to_sym, kind)
      end

      # Interpolates inflection values in the given +string+
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
        used_kinds        = options.except(*INFLECTOR_RESERVED_KEYS)
        sw, op            = @options, options
        raises            = (s=op.delete :inflector_raises).nil?            ? sw.raises            : s
        aliased_patterns  = (s=op.delete :inflector_aliased_patterns).nil?  ? sw.aliased_patterns  : s
        unknown_defaults  = (s=op.delete :inflector_unknown_defaults).nil?  ? sw.unknown_defaults  : s
        excluded_defaults = (s=op.delete :inflector_excluded_defaults).nil? ? sw.excluded_defaults : s

        idb               = @idb[locale]
        idb_strict        = @idb_strict[locale]

        string.gsub(PATTERN) do
          pattern_fix     = $1
          strict_kind     = $2
          pattern_content = $3
          ext_pattern     = $&
          ext_value       = nil
          ext_freetext    = ''
          found           = nil
          parsed_default_v= nil

          # leave escaped pattern as-is
          unless pattern_fix.empty?
            ext_pattern = ext_pattern[1..-1]
            next ext_pattern if ESCAPES[pattern_fix]
          end

          # set parsed kind if strict kind is given (named pattern is parsed) 
          if strict_kind.empty?
            parsed_symbol = nil
            strict_kind   = nil
            parsed_kind   = nil
            default_token = nil
            subdb         = idb
          else
            parsed_symbol = (NAMED_MARKER + strict_kind).to_sym
            strict_kind   = strict_kind.to_sym
            parsed_kind   = strict_kind
            subdb         = idb_strict
            default_token = subdb.get_default_token(parsed_kind)
          end

          # process pattern content's
          pattern_content.scan(TOKENS) do
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
            ext_token.split(OPERATOR_MULTI).each do |t|
              # token name corrupted
              if t.empty?
                raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                next
              end

              # mark negative-matching tokens and put them to negatives fast list
              if t[0..0] == OPERATOR_NOT
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
                parsed_symbol = kind.to_sym
                default_token = subdb.get_default_token(parsed_kind)
              elsif parsed_kind != kind
                # tokens of different kinds in one regular (not named) pattern are prohibited
                if raises
                  raise I18n::MisplacedInflectionToken.new(ext_pattern, t, parsed_symbol)
                end
                next
              end

              # use that token
              tokens[t] = true unless negatives[t]
            end

            # self-explanatory
            if (tokens.empty? && negatives.empty?)
              raise I18n::InvalidInflectionToken.new(ext_pattern, ext_token) if raises
            end

            # try @-style option for strict kind, fallback to regular if not found
            # and memorize option name for error reporting
            oname = !strict_kind.nil? && options.has_key?(parsed_symbol) ?
                    parsed_symbol : (options.has_key?(kind) ? kind : nil)

            # Get option if possible and memorize for error reporting;
            # fallback to default token if option still not found
            if oname.nil?
              option      = default_token
              orig_option = nil
            else
              option      = options[oname]
              orig_option = option
            end

            if (option.nil? || option.to_s.empty?)
              # if option is given but is unknown, empty or nil
              # then use default option for a kind if unknown_defaults is switched on
              option = unknown_defaults ? default_token : nil
            else
              # validate option and if it's unknown try in aliases
              option = subdb.get_true_token(option.to_sym, strict_kind)

              # if still nothing then fall back to default value
              # for a kind if unknown_defaults switch is on
              if option.nil?
                option = unknown_defaults ? default_token : nil
              end
            end

            # if the option is still unknown or bad
            # raise an exception
            if option.nil?
              if raises
                if oname.nil?
                  ex          = InflectionOptionNotFound
                  oname       = parsed_symbol
                  orig_option = nil
                else
                  ex          = InflectionOptionIncorrect
                end
                raise ex.new(ext_pattern, oname, ext_token, orig_option)
              end
              next
            end

            # memorize default value for further processing
            # outside this block if excluded_defaults switch is on
            parsed_default_v = ext_value if (excluded_defaults && !default_token.nil?)

            # throw the value if the given option matches one of the tokens from group
            # or negatively matches one of the negated tokens
            case negatives.count
            when 0 then next unless tokens[option]
            when 1 then next if  negatives[option]
            end

            # skip further evaluation of the pattern
            # since the right token has been found
            found = option
            break

          end # single token (or a group) processing

          # return value of a token that matches option's value
          # given for a kind or try to return a free text
          # if it's present
          if found.nil?
            # if there is excluded_defaults switch turned on
            # and a correct token was found in an inflection option but
            # has not been found in a pattern then interpolate
            # the pattern with a value picked for the default
            # token for that kind if a default token was present
            # in a pattern
            ext_value = (excluded_defaults && !parsed_kind.nil? &&
                         subdb.has_token?(options[parsed_kind], parsed_kind)) ?
                         parsed_default_v : nil
          elsif ext_value == LOUD_MARKER  # interpolate loud tokens
            ext_value = subdb.get_description(found, parsed_kind)
          elsif LOUD_ESCAPES[ext_value]
            ext_value = LOUD_MARKER
          end

          pattern_fix + (ext_value || ext_freetext)

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
      # @overload tkl_args(token)
      #   Prepares arguments containing +token+.
      #   @param [String,Hash] token the token
      #   @return [Array<Symbol,Symbol,Symbol>] the array containing
      #     cleaned and validated +token+ and the current locale
      # @overload tkl_args(token, strict_kind)
      #   Prepares arguments containing +token+ and +strict_kind+.
      #   @param [String,Hash] token the token
      #   @param [String,Hash] strict_kind the strict kind identifier beginning with +@+ symbol
      #   @return [Array<Symbol,Symbol,Symbol>] the array containing
      #     cleaned and validated +token+, +strict_kind+ and the current locale
      def tkl_args(args)
        token, kind, locale = case args.count
        when 1 then [args[0], nil, nil]
        when 2 then args[1].to_s[0..0] == NAMED_MARKER ? [args[0], args[1], nil] : [args[0], nil, args[1]]
        when 3 then args
        else raise ArgumentError.new("wrong number of arguments: #{args.count} for (1..3)")
        end
        [token,kind,locale]
      end

    end # class API

    # @abstract This is for backward compatibility with the old naming scheme.
    class Core < API
    end

  end # module Inflector
end # module I18n
