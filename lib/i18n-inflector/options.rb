# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains a class used to set up some options,
# for engine.

module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations.
    # 
    # All global options are available for current backend's inflector by
    # calling:
    #   I18n.backend.inflector.options.<option_name>
    # or just:
    #   I18n.inflector.options.<option_name>
    # A global option may be overriden by passing a proper option to
    # the translation method. Such option should have the name of a
    # global option but prefixed with +inflector_+:
    #   translate('welcome', :inflector_<option_name> => value)
    class InflectionOptions

      # This is a switch that enables extended error reporting. When it's enabled then
      # errors are raised in case of unknown or empty tokens present in a pattern
      # or in options. This switch is by default set to +false+.
      # 
      # @note Local option +:raises+ passed to the {I18n::Backend::Inflector#translate}
      #   overrides this setting.
      # 
      # @api public
      # @return [Boolean] state of the switch
      # @param [Boolean] state +true+ enables, +false+ disables this switch
      attr_accessor :raises

      # This is a switch that enables you to use aliases in patterns. When it's enabled then
      # aliases may be used in inflection patterns, not only true tokens. This operation
      # may make your translation data a bit messy if you're not alert.
      # That's why this switch is by default set to +false+.
      # 
      # @note Local option +:aliased_patterns+ passed to the {I18n::Backend::Inflector#translate}
      #   overrides this setting.
      # 
      # @api public
      # @return [Boolean] state of the switch
      # @param [Boolean] state +true+ enables, +false+ disables this switch
      attr_accessor :aliased_patterns

      # When this switch is set to +true+ then inflector falls back to the default
      # token for a kind if an inflection option passed to the {I18n::Backend::Inflector#translate} is unknown
      # or +nil+. Note that the value of the default token will be
      # interpolated only when this token is present in a pattern. This switch
      # is by default set to +true+.
      # 
      # @note Local option +:unknown_defaults+ passed to the {I18n::Backend::Inflector#translate}
      #   overrides this setting.
      # 
      # @api public
      # @return [Boolean] state of the switch
      # @param [Boolean] state +true+ enables, +false+ disables this switch
      # 
      # @example YAML:
      #    en:
      #     i18n:
      #       inflections:
      #         gender:
      #           n:       'neuter'
      #           o:       'other'
      #           default:  n
      # 
      #     welcome:         "Dear @{n:You|o:Other}"
      #     welcome_free:    "Dear @{n:You|o:Other|Free}"
      #   
      # @example Example 1
      #   
      #   # :gender option is not present,
      #   # unknown tokens in options are falling back to default
      #    
      #   I18n.t('welcome')
      #   # => "Dear You"
      #   
      #   # :gender option is not present,
      #   # unknown tokens from options are not falling back to default
      #   
      #   I18n.t('welcome', :unknown_defaults => false)
      #   # => "Dear You"
      # 
      #   # other way of setting an option – globally
      #   
      #   I18n.inflector.options.unknown_defaults = false
      #   I18n.t('welcome')
      #   # => "Dear You"
      #   
      #   # :gender option is not present, free text is present,
      #   # unknown tokens from options are not falling back to default
      #   
      #   I18n.t('welcome_free', :unknown_defaults => false)
      #   # => "Dear You"
      #   
      # @example Example 2
      #   
      #   # :gender option is nil,
      #   # unknown tokens from options are falling back to default token for a kind
      #   
      #   I18n.t('welcome', :gender => nil)
      #   # => "Dear You"
      #   
      #   # :gender option is nil
      #   # unknown tokens from options are not falling back to default token for a kind
      #   
      #   I18n.t('welcome', :gender => nil, :unknown_defaults => false)
      #   # => "Dear "
      #   
      #   # :gender option is nil, free text is present
      #   # unknown tokens from options are not falling back to default token for a kind
      #   
      #   I18n.t('welcome_free', :gender => nil, :unknown_defaults => false)
      #   # => "Dear Free"
      # 
      # @example Example 3
      #   
      #   # :gender option is unknown,
      #   # unknown tokens from options are falling back to default token for a kind
      #   
      #   I18n.t('welcome', :gender => :unknown_blabla)
      #   # => "Dear You"
      #   
      #   # :gender option is unknown,
      #   # unknown tokens from options are not falling back to default token for a kind
      #   
      #   I18n.t('welcome', :gender => :unknown_blabla, :unknown_defaults => false)
      #   # => "Dear "
      #   
      #   # :gender option is unknown, free text is present
      #   # unknown tokens from options are not falling back to default token for a kind
      #   
      #   I18n.t('welcome_free', :gender => :unknown_blabla, :unknown_defaults => false)
      #   # => "Dear Free"
      attr_accessor :unknown_defaults

      # When this switch is set to +true+ then inflector falls back to the default
      # token for a kind if the given inflection option is correct but doesn't exist in a pattern.
      # 
      # There might happend that the inflection option
      # given to {#translate} method will contain some proper token, but that token
      # will not be present in a processed pattern. Normally an empty string will
      # be generated from such a pattern or a free text (if a local fallback is present
      # in a pattern). You can change that behavior and tell interpolating routine to
      # use the default token for a processed kind in such cases.
      # 
      # This switch is by default set to +false+.
      # 
      # @note Local option +:excluded_defaults+ passed to the {I18n::Backend::Inflector#translate}
      #   overrides this setting.
      # 
      # @api public
      # @return [Boolean] state of the switch
      # @param [Boolean] state +true+ enables, +false+ disables this switch
      # 
      # @example YAML:
      #   en:
      #     i18n:
      #       inflections:
      #         gender:
      #           o:      "other"
      #           m:      "male"
      #           n:      "neuter"
      #           default: n
      #   
      #     welcome:  'Dear @{n:You|m:Sir}'
      # @example Usage of +:excluded_defaults+ option
      #   I18n.t('welcome', :gender => :o)
      #   # => "Dear "
      #   
      #   I18n.t('welcome', :gender => :o, :excluded_defaults => true)
      #   # => "Dear You"
      attr_accessor :excluded_defaults

      # This method initializes all internal structures.
      def initialize
        reset
        generate_known_options
      end

      # This method resets all options to their default values.
      # 
      # @return [void]
      def reset
        @excluded_defaults  = false
        @unknown_defaults   = true
        @aliased_patterns   = false
        @raises             = false
        nil
      end

      # This method processes the given argument
      # in a way that it will use default values
      # for options that are missing.
      # 
      # @api public
      # @note It modifies the given object.
      # @param [Hash] options the options
      # @return [Hash] the given options
      def prepare_options!(options)
        @known.
        reject { |name,long| options.has_key?(long) }.
        each   { |name,long| options[long] = instance_variable_get(name) }
        options
      end

      # This method prepares options for translate method.
      # That means removal of all kind-related options
      # and all options that are flags.
      # 
      # @api public
      # @note It modifies the given object.
      # @param [Hash] options the given options
      # @return [Hash] the given options
      def prepare_for_translate!(options)
        @known.each { |name,long| options.delete long }
        options
      end

      # Lists all known options in a long format
      # (each name preceeded by <tt>inflector_</tt>).
      # 
      # @api public
      # @return [Array<Symbol>] the known options
      def known
        @known.values
      end

      protected

      # This method generates known options map
      # so their names are easy to access.
      # 
      # @return [void]
      def generate_known_options
        k = Hash.new
        instance_variables.map do |opt|
          sopt = opt.to_sym
          next if sopt == :@known
          k[sopt] = ('inflector_' + opt[1..-1]).to_sym
        end
        @known = LazyHashEnumerator.new(k)
        nil
      end

    end

  end
end
