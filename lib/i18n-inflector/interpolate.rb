# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains I18n::Inflector::Interpolate module,
# which is included in the API.

module I18n
  module Inflector

    # This module contains methods for interpolating
    # inflection patterns.
    module Interpolate

      include I18n::Inflector::Config

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
      # @option options [Boolean] :inflector_cache_aware (false) local switch
      #   that overrides global setting (see: {I18n::Inflector::InflectionOptions#cache_aware})
      # @return [String] the string with interpolated patterns
      def interpolate(string, locale, options = {})
        interpolate_core(string, locale, options)
      end

      private

      # @private
      def interpolate_core(string, locale, options)
        option_kinds      = options.except(*Reserved::KEYS)
        raises            = options[:inflector_raises]
        aliased_patterns  = options[:inflector_aliased_patterns]
        unknown_defaults  = options[:inflector_unknown_defaults]
        excluded_defaults = options[:inflector_excluded_defaults]

        idb               = @idb[locale]
        idb_strict        = @idb_strict[locale]

        string.gsub(PATTERN_REGEXP) do
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
            next ext_pattern if Escapes::PATTERN[pattern_fix]
          end

          # set parsed kind if strict kind is given (named pattern is parsed) 
          if strict_kind.empty?
            sym_parsed_kind = nil
            strict_kind     = nil
            parsed_kind     = nil
            default_token   = nil
            subdb           = idb
          else
            sym_parsed_kind = (Markers::PATTERN + strict_kind).to_sym
            if strict_kind.include?(Operators::Tokens::AND)

              # Complex markers processing
              begin
                ext_value = interpolate_complex(strict_kind,
                                                pattern_content,
                                                locale, options)
              rescue I18n::InflectionPatternException => e
                e.pattern = ext_pattern
                raise
              end
              found = pattern_content = "" # disable further processing

            else

              # Strict kinds preparing
              subdb = idb_strict

              # validate strict kind and set needed variables
              if (Reserved::Kinds.invalid?(strict_kind, :PATTERN) ||
                  !idb_strict.has_kind?(strict_kind.to_sym))
                raise I18n::InvalidInflectionKind.new(locale, ext_pattern, sym_parsed_kind) if raises
                # Take a free text for invalid kind and return it
                next pattern_fix + pattern_content.scan(TOKENS_REGEXP).reverse.
                                   select { |t,v,f| t.nil? && !f.nil? }.
                                   map    { |t,v,f| f.to_s            }.
                                   first.to_s
              else
                strict_kind   = strict_kind.to_sym
                parsed_kind   = strict_kind
                default_token = subdb.get_default_token(parsed_kind)
              end

            end
          end

          # process pattern content's
          pattern_content.scan(TOKENS_REGEXP) do
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
                raise I18n::InvalidInflectionToken.new(locale, ext_pattern, ext_token) if raises
              end
              next
            end

            # split tokens from group if comma is present and put into fast list
            ext_token.split(Operators::Token::OR).each do |t|
              # token name corrupted
              if t.to_s.empty?
                raise I18n::InvalidInflectionToken.new(locale, ext_pattern, t) if raises
                next
              end

              # mark negative-matching token and put it on the negatives fast list
              if t[0..0] == Operators::Token::NOT
                t = t[1..-1]
                negative = true
              else
                negative = false
              end

              # is token name corrupted?
              if Reserved::Tokens.invalid?(t, :PATTERN)
                raise I18n::InvalidInflectionToken.new(locale, ext_pattern, t) if raises
                next
              end

              t = t.to_sym
              t = subdb.get_true_token(t, strict_kind) if aliased_patterns
              negatives[t] = true if negative

              # get a kind for that token
              kind  = subdb.get_kind(t, strict_kind)
              if kind.nil?
                if raises
                  # regular pattern and token that has a bad kind
                  if strict_kind.nil? # fixme - retest when it's raised
                    raise I18n::InvalidInflectionToken.new(locale, ext_pattern, t, sym_parsed_kind)
                  else
                    # named pattern (kind validated before, so the only error is misplaced token)
                    raise I18n::MisplacedInflectionToken.new(locale, ext_pattern, t, sym_parsed_kind)
                  end
                end
                next
              end

              # set processed kind after matching first token in a pattern
              if parsed_kind.nil?
                parsed_kind   = kind
                sym_parsed_kind = kind.to_sym
                default_token = subdb.get_default_token(parsed_kind)
              elsif parsed_kind != kind
                # tokens of different kinds in one regular (not named) pattern are prohibited
                raise I18n::MisplacedInflectionToken.new(locale, ext_pattern, t, sym_parsed_kind) if raises
                next
              end

              # use that token
              tokens[t] = true unless negatives[t]
            end

            # self-explanatory
            if (tokens.empty? && negatives.empty?)
              raise I18n::InvalidInflectionToken.new(locale, ext_pattern, ext_token) if raises
            end

            # try @-style option for strict kind, fallback to regular if not found
            # and memorize option name
            oname = !strict_kind.nil? && option_kinds.has_key?(sym_parsed_kind) ?
                    sym_parsed_kind : (option_kinds.has_key?(kind) ? kind : nil)

            # Get option if possible and memorize for error reporting;
            # fallback to default token if option still not found
            # orig_option is for error reporting
            if oname.nil?
              option      = default_token
              orig_option = nil
            else
              option      = option_kinds[oname]
              orig_option = option
              option      = default_token if option == Keys::DEFAULT_TOKEN
            end

            if (option.nil? || option.to_s.empty?)
              # if option is given but is unknown, empty or nil
              # then use default option for a kind if unknown_defaults is switched on
              option = unknown_defaults ? default_token : nil
            else
              # validate option's name
              if Reserved::Kinds.invalid?(option, :OPTION)
                raise I18n::InvalidInflectionOption.new(locale, ext_pattern, option) if raises
                option = nil
              else
                # validate option and if it's unknown try in aliases
                option = subdb.get_true_token(option.to_sym, strict_kind)
              end

              # if still nothing then fall back to default value
              # for a kind if unknown_defaults switch is on
              if option.nil?
                option = unknown_defaults ? default_token : nil
              end
            end

            # if the option is still unknown or bad
            # then raise an exception
            if option.nil?
              if raises
                if oname.nil?
                  ex          = InflectionOptionNotFound
                  oname       = sym_parsed_kind
                  orig_option = nil
                else
                  ex          = InflectionOptionIncorrect
                end
                raise ex.new(locale, ext_pattern, ext_token, oname, orig_option)
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
                         subdb.has_token?(option_kinds[parsed_kind], parsed_kind)) ?
                         parsed_default_v : nil
          elsif ext_value == Markers::LOUD_VALUE  # interpolate loud tokens
            ext_value = subdb.get_description(found, parsed_kind)
          elsif ext_value[0..0] == Escapes::ESCAPE
            ext_value.sub!(Escapes::ESCAPE_R, '\1')
          end

          pattern_fix + (ext_value || ext_freetext)

        end # single pattern processing

      end # def interpolate

      # This is a helper that reduces a complex inflection pattern
      # by producing equivalent of regular patterns of it and
      # by interpolating them using {#interpolate} method.
      # 
      # @param [String] complex_kind the complex kind (many kinds separated
      #   by the {Operators::Tokens::AND})
      # @param [String] content the content of the processed pattern
      # @param [Symbol] locale the locale to use
      # @param [Hash] options the options
      # @return [String] the interpolated pattern
      def interpolate_complex(complex_kind, content, locale, options)
        result      = nil
        free_text   = ""
        kinds       = complex_kind.split(Operators::Tokens::AND).
                      reject{ |k| k.nil? || k.empty? }.each

        begin

          content.scan(TOKENS_REGEXP) do |tokens, value, free|
            if tokens.nil?
              raise IndexError.new if free.empty?
              free_text = free
              next
            end

            kinds.rewind

            # process each token from set
            results = tokens.split(Operators::Tokens::AND).map do |token|
              raise IndexError.new if token.empty?
              if value == Markers::LOUD_VALUE
                r = interpolate_core("#{Markers::PATTERN}#{kinds.next}{#{token}:#{value}|@}", locale, options)
                break if r == Markers::PATTERN
              else
                r = interpolate_core("#{Markers::PATTERN}#{kinds.next}{#{token}:#{value}}", locale, options)
                break if r != value # stop with this set, because something is not matching
              end
              r
            end

            # some token didn't matched, try another set
            next if results.nil?

            # generate result for set or raise error
            if results.size == kinds.count
              result = value == Markers::LOUD_VALUE ? results.join(' ') : value
              break
            else
              raise IndexError.new
            end

          end # scan tokens

        rescue IndexError, StopIteration

          if options[:inflector_raises]
            raise I18n::ComplexPatternMalformed.new(locale, content, nil, complex_kind)
          end
          result = nil

        end

        result || free_text

      end

    end # module Interpolate
  end # module Inflector
end # module I18n
