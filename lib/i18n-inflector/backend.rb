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
    
    # This module contains methods that are adding
    # tokenized inflection support to internal I18n classes.
    # Usually you don't have to know what's here to use it.
    module Inflector

      include I18n::Inflector::Util

      # This is the accessor that allows to set
      # a few switches controlling the inflection engine.
      # 
      # @return [I18n::Inflector::InflectionOptions] the inflection options
      def inflection_options
        inflector_try_init
        @inflection_options
      end

      # Cleans up internal hashes containg kinds, inflections and aliases.
      # 
      # @api public
      # @note It calls {I18n::Backend::Simple#reload! I18n::Backend::Simple#reload!}
      # @return [Boolean] the result of calling ancestor's method
      # @see I18n::Inflector.reload! Short name: I18n::Inflector.reload!
      def reload!
        @idb = nil
        I18n::Inflector.send(:init_frontend, @idb)
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

        unless translated_string.include?(I18n::Inflector::FAST_MATCHER)
          return translated_string
        end

        inflections = @idb[locale]
        if (inflections.nil? || inflections.empty?)
          return clear_inflection_patterns(translated_string)
        end

        interpolate_inflections(translated_string, locale, options.dup)
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
              @idb.delete locale
              load_inflection_tokens(locale, r[:i18n][:inflections])
            end
          end
        end
        r
      end

      # @private
      def inflector_try_init_backend
        init_translations unless initialized?
      end

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

      # Checks the state of the switch that enables usage of aliases in patterns.
      # 
      # @api public
      # @note This is a helper method, you can use {#inflector_aliased_patterns accessor} instead.
      # @return [Boolean] the value of the global switch or the passed variable
      # @see I18n::Inflector.aliased_patterns? Short name: I18n::Inflector.aliased_patterns?
      # @see #inflector_aliased_patterns=
      # @overload inflector_aliased_patterns?
      #   Checks the state of the switch that enables usage of aliases in patterns.
      #   @return [Boolean] the value of the global switch
      # @overload inflector_aliased_patterns?(value)
      #   Returns the given value.
      #   @param [Boolean] value the value to be returned
      #   @return [Boolean] +true+ if the passed +value+ is not +false+
      def inflector_aliased_patterns?(option=nil)
        option.nil? ? @inflector_aliased_patterns : option!=false      
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

      protected

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
        used_kinds        = options.except(*I18n::Inflector::INFLECTOR_RESERVED_KEYS)
        sw, op            = @inflection_options, options
        raises            = (s=op.delete :inflector_raises).nil?            ? sw.raises            : s 
        aliased_patterns  = (s=op.delete :inflector_aliased_patterns).nil?  ? sw.aliased_patterns  : s
        unknown_defaults  = (s=op.delete :inflector_unknown_defaults).nil?  ? sw.unknown_defaults  : s
        excluded_defaults = (s=op.delete :inflector_excluded_defaults).nil? ? sw.excluded_defaults : s

        idb               = @idb[locale]

        string.gsub(I18n::Inflector::PATTERN) do
          pattern_fix     = $1
          pattern_content = $2
          ext_pattern     = $&
          parsed_kind     = nil
          default_token   = nil
          ext_value       = nil
          ext_freetext    = ''
          found           = false
          parsed_default_v= nil

          # leave escaped pattern as is
          next ext_pattern[1..-1] if I18n::Inflector::ESCAPES.has_key?(pattern_fix)

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
                negatives[t.to_sym] = true
              end
              
              t = t.to_sym

              # get kind for that token
              kind  = idb.get_kind(t)
              if kind.nil?
                raise I18n::InvalidInflectionToken.new(ext_pattern, t) if raises
                next
              end

              # set processed kind after matching first token in a pattern
              if parsed_kind.nil?
                parsed_kind   = kind
                default_token = idb.get_default_token(parsed_kind)
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
              option = idb.get_true_token(option.to_sym)

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
            next if (!tokens[option] && (negatives.empty? || negatives[option]))

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
            kind    = idb.get_kind(token)
            result  = parsed_default_v unless kind.nil?
          end

          pattern_fix + (result || ext_freetext)

        end # single pattern processing

      end

      # Initializes internal hashes used for keeping inflections configuration.
      # 
      # @return [void]
      def inflector_try_init
        return nil if (defined?(@idb) && !@idb.nil?)

        @idb = {}
        @inflection_options ||= I18n::Inflector::InflectionOptions.new
        I18n::Inflector.send(:init_frontend, @idb)
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
        translated_string.gsub(I18n::Inflector::PATTERN,'')
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
        return @idb[locale] if @idb.has_key?(locale)
        inflections_tree = subtree || inflection_subtree(locale)
        return nil if (inflections_tree.nil? || inflections_tree.empty?)

        @idb[locale]  = I18n::Inflector::InflectionData.new
        idb           = @idb[locale]

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
