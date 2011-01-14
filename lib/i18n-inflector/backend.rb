# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Backend::Inflector module,
# which extends I18n::Backend::Simple by adding the ability
# to interpolate patterns containing inflection tokens
# defined in translation data.

module I18n

  # @abstract This namespace is shared with I18n subsystem.
  module Backend

    # This module contains methods that are adding
    # tokenized inflection support to internal I18n classes.
    # It is intened to be included in the Simple backend
    # module so that it will patch translate method in order
    # to interpolate additional inflection tokens present in translations.
    # Usually you don't have to know what's here to use it.
    module Inflector

      # This accessor allows to reach API methods of the
      # inflector object associated with this class.
      def inflector
        inflector_try_init
        @inflector
      end

      # Cleans up internal hashes containg kinds, inflections and aliases.
      # 
      # @api public
      # @note It calls {I18n::Backend::Simple#reload! I18n::Backend::Simple#reload!}
      # @return [Boolean] the result of calling ancestor's method
      def reload!
        @inflector = nil
        super
      end

      # Translates given key taking care of inflections.
      # 
      # @api public
      # @see I18n::Inflector::Core#interpolate
      # @see I18n::Inflector::InflectionOptions
      # @param [Symbol] locale locale
      # @param [Symbol,String] key translation key
      # @param [Hash] options a set of options to pass to the translation routines.
      # @note Inflector requires at least one of the +options+ to have a value that
      #   corresponds with token present in a pattern (or its alias). The name of that
      #   particular option should be the same as the name of a kind of tokens from a pattern.
      #   All +options+ along with a +string+ and +locale+ are passed to
      #   {I18n::Backend::Simple#translate I18n::Backend::Simple#translate}
      #   and the result is processed by {I18n::Inflector::Core#interpolate}
      # @return [String] the translated string with interpolated patterns
      def translate(locale, key, options = {})
        translated_string = super

        return translated_string if locale.to_s.empty?

        unless @inflector.inflected_locale?(locale)
          return translated_string.gsub(I18n::Inflector::PATTERN,'')
        end

        unless translated_string.include?(I18n::Inflector::FAST_MATCHER)
          return translated_string
        end

        @inflector.interpolate(translated_string, locale, options.dup)
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
        inflector_try_init
        if data.respond_to?(:has_key?)
          subdata = (data[:i18n] || data['i18n'])
          unless subdata.nil?
            subdata = (subdata[:inflections] || subdata['inflections'])
            unless subdata.nil?
              inflection_data = load_inflection_tokens(locale, r[:i18n][:inflections])
              @inflector.add_database(inflection_data)
            end
          end
        end
        r
      end

      protected

      # Initializes internal hashes used for keeping inflections configuration.
      # 
      # @return [void]
      def inflector_try_init
        return nil if (defined?(@inflector) && !@inflector.nil?)
        @inflector  = I18n::Inflector::Core.new
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

      # Gives an access to the internal structure containing configuration data
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

        if value[0..0] != I18n::Inflector::ALIAS_MARKER
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
      # @return [Hash,nil] the internal Hash containing inflections tokens or +nil+ if something went wrong
      # @raise [I18n::BadInflectionToken] if a name of some loaded token is invalid
      # @raise [I18n::BadInflectionAlias] if a loaded alias points to a token that does not exists
      # @raise [I18n::DuplicatedInflectionToken] if a token has already appeard in loaded configuration
      # @overload load_inflection_tokens(locale)
      #   @note That version calls the {inflection_subtree} method to obtain internal translations data.
      #   Loads inflection tokens for the given locale using internal hash of stored translations. Requires
      #   translations to be initialized.
      #   @param [Symbol] locale the locale to use and work for
      #   @return [Hash,nil] the internal Hash containing inflections or +nil+ if translations were not initialized
      # @overload load_inflection_tokens(locale, subtree)
      #   Loads inflection tokens for the given locale using data given in an argument
      #   @param [Symbol] locale the locale to use and work for
      #   @param [Hash] subtree the tree (in a form of nested Hashes) containing inflection tokens to scan
      #   @return [Hash,nil] the internal Hash containing inflections or +nil+ if the given subtree was wrong or empty
      def load_inflection_tokens(locale, subtree=nil)
        inflections_tree = subtree || inflection_subtree(locale)
        return nil if (inflections_tree.nil? || inflections_tree.empty?)

        idb = I18n::Inflector::InflectionData.new(locale)

        inflections_tree.each_pair do |kind, tokens|
          tokens.each_pair do |token, description|

            # test for duplicate
            if idb.has_token?(token)
              raise I18n::DuplicatedInflectionToken.new(idb.get_kind(token), kind, token)
            end

            # validate token's name
            raise I18n::BadInflectionToken.new(locale, token, kind) if token.to_s.empty?

            # validate token's description
            if description.nil?
              raise I18n::BadInflectionToken.new(locale, token, kind, description)
            elsif description[0..0] == I18n::Inflector::ALIAS_MARKER
              next
            end

            # handle default token for a kind
            if token == :default
              if idb.has_default_token?(kind) # should never happend unless someone is messing with @translations
                raise I18n::DuplicatedInflectionToken.new(kind, nil, token)
              end
              idb.set_default_token(kind, description)
              next
            end

            idb.add_token(token, kind, description)
          end
        end

        # handle aliases
        inflections_tree.each_pair do |kind, tokens|
          tokens.each_pair do |token, description|
            next if description[0..0] != I18n::Inflector::ALIAS_MARKER
            real_token = shorten_inflection_alias(token, kind, locale, inflections_tree)
            idb.add_alias(token, real_token) unless real_token.nil?
          end
        end

        # process and validate defaults
        valid = idb.validate_default_tokens
        raise I18n::BadInflectionAlias.new(locale, :default, valid[0], valid[1]) unless valid.nil?

        idb
      end

    end
  end
end
