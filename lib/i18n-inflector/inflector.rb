# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Inflector module,
# which extends I18n by adding the ability
# to interpolate patterns containing inflection tokens
# defined in translation data and manipulate on that data.

module I18n

  class <<self
    # This is proxy method that returns an inflector
    # object used by the current I18n backend.
    # 
    # @return [I18n::Inflector::Core] inflector the inflector
    #   used by the current backend
    def inflector
      I18n.backend.inflector
    end
  end

  module Inflector

    # @private
    def get_reserved_keys
      return I18n::RESERVED_KEYS                  if defined?(I18n::RESERVED_KEYS)
      return I18n::Backend::Base::RESERVED_KEYS   if defined?(I18n::Backend::Base::RESERVED_KEYS)
      return I18n::Backend::Simple::RESERVED_KEYS if defined?(I18n::Backend::Simple::RESERVED_KEYS)
      return RESERVED_KEYS if defined?(RESERVED_KEYS)
      []
    end
    module_function :get_reserved_keys

    # Contains <tt>@</tt> string that is used to quickly fallback
    # to standard +translate+ method if it's not found.
    FAST_MATCHER  = '@'

    # Contains a regular expression that catches patterns.
    PATTERN       = /(.?)@([^\{]*)\{([^\}]+)\}/

    # Contains a regular expression that catches tokens.
    TOKENS        = /(?:([^\:\|]+):+([^\|]+)\1?)|([^:\|]+)/ 

    # Contains a symbol that indicates an alias.
    ALIAS_MARKER  = '@'

    # Contains a symbol that indicates a named pattern.
    NAMED_MARKER  = '+'

    # Conatins a symbol used to separate multiple tokens.
    OPERATOR_MULTI = ','

    # Conatins a symbol used to mark tokens as negative.
    OPERATOR_NOT  = '!'

    # Contains a list of escape symbols that cause pattern to be escaped.
    ESCAPES       = { '@' => true, '\\' => true }

    # Reserved keys
    INFLECTOR_RESERVED_KEYS = I18n::Inflector.get_reserved_keys

    # Instances of this class, the inflectors, are attached
    # to I18n backends. This class contains common operations
    # that programmer can perform on inflections. It keeps the
    # database of {I18n::Inflector::InflectionStore} instances
    # and has methods to access them in an easy way.
    # 
    # ==== Usage
    # You can access the instance of this class attached to
    # default I18n backend by entering:
    #   I18n.backend.inflector
    # or in a short form:
    #   I18n.inflector
    # In case of named patterns:
    #   I18n.inflector.named
    class Core < API

      attr_reader :named

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

      # Initilizes inflector by creating internal databases for storing
      # inflection hashes and options.
      # 
      # @api public
      def initialize
        super
        @idb      = {}
        @options  = I18n::Inflector::InflectionOptions.new
        @named    = I18n::Inflector::API::Named.new(@idb, @options)
      end

      # Adds database for the specified locale.
      # 
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @param [Symbol] locale the locale for which the infleciton database is created
      # @return [I18n::Inflector::InflectionStore] the new object for keeping inflection data
      #   for the given +locale+
      def new_database(locale)
        locale = prep_locale(locale)
        @idb[locale] = I18n::Inflector::InflectionStore.new(locale)
      end

      # Attaches {I18n::Inflector::InflectionStore} instance to the
      # current collection.
      #
      # @api public
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @note It doesn't create copy of inflection data, it registers the given object.
      # @param [I18n::Inflector::InflectionStore] idb inflection data to add
      # @return [I18n::Inflector::InflectionStore] the given +idb+ or +nil+ if something
      #   went wrong (e.g. +nil+ was given as an argument)
      def add_database(idb)
        return nil if idb.nil?
        locale = prep_locale(idb.locale)
        delete_database(locale)
        @idb[locale] = idb
      end

      # Deletes a database for the specified locale.
      # 
      # @api public
      # @note It detaches the database from {I18n::Inflector::Core} instance.
      #   Other objects referring to it directly may still use it.
      # @raise [I18n::InvalidLocale] if there is no proper locale name
      # @param [Symbol] locale the locale for which the infleciton database is to be deleted.
      # @return [void]
      def delete_database(locale)
        locale = prep_locale(locale)
        return nil if @idb[locale].nil?
        @idb[locale] = nil
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

          # set parsed kind if strict kind is given (named pattern is present)

          strict_kind = nil if (!strict_kind.nil? && strict_kind.empty?)

          unless strict_kind.nil?
            strict_kind   = strict_kind.to_sym
            parsed_kind   = strict_kind
            subdb         = idb.strict
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

    end # class Core

  end # module Inflector
end # module I18n
