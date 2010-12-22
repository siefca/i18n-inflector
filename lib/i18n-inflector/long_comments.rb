# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2010 by Paweł Wilk
# License::   This program is licensed under the terms of {GNU Lesser General Public License}[link:docs/LGPL-LICENSE.html] or {Ruby License}[link:docs/COPYING.html].
# 
# This file contains inline documentation data
# that would make the file with code less readable
# if placed there.
# 
#--
# 
# Copyright (C) 2010 by Paweł Wilk. All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of either: 1) the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version; or 2) Ruby's License.
# 
# See the file COPYING for complete licensing information.
#
#++
module I18n
  module Backend
    # Overwrites the Simple backend translate method so that it will interpolate
    # additional inflection tokens present in translations. These tokens may
    # appear in *patterns* which are contained within <tt>@{</tt> and <tt>}</tt>
    # symbols.
    # 
    # You can choose different kinds (gender, title, person, time, author, etc.)
    # of tokens to group them in a meaningful, semantical sets. That means you can
    # apply Inflector to do simple inflection by a gender or a person, when some
    # language requires it.
    # 
    # To achieve similar functionality lambdas can be used but there might be
    # some areas of appliance that including proc objects in translations
    # is prohibited.
    # If you have a troop of happy translators that shouldn't have the
    # ability to execute any code yet you need some simple inflection
    # then you can make use of this module.
    # == Usage
    #   require 'i18-inflector'
    #   
    #   i18n.translate('welcome')
    #   # where welcome maps to: "Dear @{f:Madam|m:Sir}"
    #
    # == Inflection pattern
    # An example inflection pattern contained in a translation record looks like:
    #   welcome: "Dear @{f:Madam|m:Sir|n:You|All}"
    # 
    # The +f+, +m+ and +n+ are inflection *tokens* and +Madam+, +Sir+, +You+ and
    # +All+ are *values*. Only one value is going to replace the whole
    # pattern. To select which one an additional option is used. That option
    # must be passed to translate method.
    # 
    # == Configuration
    # To recognize tokens present in patterns this module uses keys grouped
    # in the scope called +inflections+ for a given locale. For instance
    # (YAML format):
    #   en:
    #     i18n:
    #       inflections:
    #         gender:
    #           f:      "female"
    #           m:      "male"
    #           n:      "neuter"
    #           woman:  @f
    #           man:    @m
    #           default: n
    # 
    # Elements in the example above are:
    # * +en+: language
    # * +i18n+: configuration scope
    # * +inflections+: inflections configuration scope
    # * +gender+: kind scope
    # * +f+, +m+, +n+: inflection tokens
    # * <tt>"male"</tt>, <tt>"female"</tt>, <tt>"neuter"</tt>: tokens' descriptions
    # * +woman+, +man+: inflection aliases
    # * <tt>@f</tt>, <tt>@m</tt>: pointers to real tokens 
    # * +default+: default token for a kind +gender+
    # 
    # === Kind
    # Note the fourth scope selector in the example above (+gender+). It's called
    # the *kind* and contains *tokens*. We have the kind
    # +gender+ to which the inflection tokens +f+, +m+ and +n+ are
    # assigned.
    # 
    # You cannot assign the same token to more than one kind.
    # Trying to do that will raise DuplicatedInflectionToken exception.
    # This is required in order to keep patterns simple and tokens interpolation
    # fast.
    # 
    # Kind is also used to instruct I18n.translate method which
    # token it should pick. This will be explained later. 
    #
    # === Aliases
    # Aliases are special tokens that point to other tokens. They cannot
    # be used in inflection patterns but they are fully recognized values
    # of options while evaluating kinds.
    # 
    # Aliases might be helpful in multilingual applications that are using
    # a fixed set of values passed through options to describe some properties
    # of messages, e.g. +masculine+ and +feminine+ for a grammatical gender.
    # Translators may then use their own tokens (like +f+ and +m+ for English)
    # to produce pretty and intuitive patterns.
    # 
    # For example: if some application uses database with gender assigned
    # to a user which may be +male+, +female+ or +none+, then a translator
    # for some language may find it useful to map impersonal token (<tt>none</tt>)
    # to the +neuter+ token, since in translations for his language the
    # neuter gender is in use.
    # 
    # Here is the example of such situation:
    # 
    #   en:
    #     i18n:
    #       inflections:
    #         gender:
    #           male:     "male"
    #           female:   "female"
    #           none:     "impersonal form"
    #           default:  none 
    #   
    #   pl:
    #     i18n:
    #       inflections:
    #         gender:
    #           k:        "female"
    #           m:        "male"
    #           n:        "neuter"
    #           male:     @k
    #           female:   @m
    #           none:     @n
    #           default:  none
    # 
    # In the case above Polish translator decided to use neuter
    # instead of impersonal form when +none+ token will be passed
    # through the option +:gender+ to the translate method. He
    # also decided that he will use +k+, +m+ or +n+ in patterns,
    # because the names are short and correspond to gender names in
    # Polish language.
    # 
    # Aliases may point to other aliases. While loading inflections they
    # will be internally shortened and they will always point to real tokens,
    # not other aliases.
    # 
    # === Default token
    # There is special token called the +default+, which points
    # to a token that should be used if translation routine cannot deduce
    # which one it should use because a proper option was not given.
    # 
    # Default tokens may point to aliases and may use aliases' syntax, e.g.:
    #   default: @man
    # 
    # === Descriptions
    # The values of keys in the example (+female+, +male+ and +neuter+)
    # are *descriptions* which are not used by interpolation routines
    # but might be helpful (e.g. in UI). For obvious reasons you cannot
    # describe aliases.
    # 
    # == Tokens
    # The token is an element of a pattern. A pattern may have many tokens
    # of the same kind separated by vertical bars. Each token used in a
    # pattern should end with colon sign. After this colon a value should
    # appear (or an empty string). This value is to be picked by interpolation
    # routine and will replace whole pattern, when it matches the value of an
    # option passed to I18n.translate method. A name of that
    # option should be the same as a *kind* of tokens used within a pattern.
    # The first token in a pattern determines the kind of all tokens used
    # in that pattern.
    # ==== Examples
    #   # welcome is "Dear @{f:Madam|m:Sir|n:You|All}"
    #   
    #   I18n.translate('welcome', :gender => :m)
    #   # => "Dear Sir"
    #   
    #   I18n.translate('welcome', :gender => :unknown)
    #   # => "Dear All"
    #   
    #   I18n.translate('welcome')
    #   # => "Dear You"
    # 
    # In the second example the <b>fallback value</b> +All+ was interpolated
    # because the routine had been unable to find the token called +:unknown+.
    # That differs from the latest example, in which there was no option given,
    # so the default token for a kind had been applied (in this case +n+).
    # 
    # == Local fallbacks (free text)
    # The fallback value will be used when any of the given tokens from
    # pattern cannot be interpolated.
    # 
    # Be aware that enabling extended error reporting makes it unable
    # to use fallback values in most cases. Local fallbacks will then be
    # applied only when a given option contains a proper value for some
    # kind but it's just not present in a pattern, for example:
    #
    #   I18n.locale = :en
    #   I18n.backend.store_translations 'en', 'welcome' => 'Dear @{n:You|All}'   
    #   I18n.backend.store_translations 'en', :i18n     => { :inflections => {
    #                                         :gender   => { :n => 'neuter', :o => 'other' }}}
    #   
    #   I18n.translate('welcome', :gender => :o, :inflector_raises => true)
    #   # => "Dear All"
    #   
    #   # since the token :o was configured but not used in the pattern
    #
    # == Unknown and empty tokens in options
    # If an option containing token is not present at all then the interpolation
    # routine will try the default token for a processed kind if the default
    # token is present in a pattern. The same thing will happend if the option
    # is present but its value is unknown, empty or +nil+.
    # If the default token is not present in a pattern or is not defined in
    # a configuration data then the processed pattern will result in an empty
    # string or in a local fallback value if there is a free text placed
    # in a pattern.
    # 
    # You can change this default behavior and force inflector
    # not to use a default token when a value of an option for a kind is unknown,
    # empty or +nil+ but only when it's not present.
    # To do that you should set option +:inflector_unknown_defaults+ to
    # +false+ and pass it to I18n.translate method. Other way is to set this
    # globally by using the method called inflector_unknown_defaults.
    # See inflector_unknown_defaults method for examples showing how the
    # translation results are changing when that switch is applied.
    # 
    # == Mixing inflection and standard interpolation patterns
    # The Inflector module allows you to include standard <tt>%{}</tt>
    # patterns inside of inflection patterns. The value of a standard
    # interpolation variable will be evaluated and interpolated before
    # processing an inflection pattern. For example:
    #   I18nstore_translations(:xx, 'hi' => 'Dear @{f:Lady|m:%{test}}!')
    #   
    #   I18n.t('hi', :gender => :m, :locale => :xx, :test => "Dude")
    #   # => Dear Dude!
    # 
    # == Errors
    # By default the module will silently ignore any interpolation errors.
    # You can turn off this default behavior by passing +:inflector_raises+ option.
    # For instance:
    #
    #   I18n.locale = :en
    #   I18n.backend.store_translations 'en', 'welcome' => 'Dear @{m:Sir|f:Madam|Fallback}'
    #   I18n.backend.store_translations 'en', :i18n     =>  { :inflections => {
    #                                                           :gender   => {
    #                                                             :f => 'female',
    #                                                             :m => 'male'
    #                                                       }}}
    # 
    #   I18n.translate('welcome', :inflector_raises => true)
    #   # => I18n::InvalidOptionForKind: option :gender required
    #        by the pattern "@{m:Sir|f:Madam|Fallback}" was not found
    # 
    # Here are the exceptions that may be raised when option +:inflector_raises+
    # is set to +true+:
    # 
    # * I18n::InvalidOptionForKind
    # * I18n::InvalidInflectionToken
    # * I18n::MisplacedInflectionToken
    # 
    # There are also exceptions that are raised regardless of :+inflector_raises+
    # presence or value.
    # These are usually caused by critical errors encountered during processing
    # inflection data. Here is the list:
    # 
    # * I18n::InvalidLocale
    # * I18n::DuplicatedInflectionToken
    # * I18n::BadInflectionToken
    # * I18n::BadInflectionAlias
    #
    module Inflector
      # When this switch is set to +true+ then inflector falls back to the default
      # token for a kind if an option passed to the translate method that describes
      # a kind is unknown or +nil+. Note that the value for a default token will be
      # interpolated only when this token is present in pattern. This switch
      # is by default set to +true+.
      # 
      # Local option +:inflector_unknown_defaults+ passed to translation method
      # overrides this setting.
      # 
      # === Short name
      # <tt>I18n::Inflector.unknown_defaults</tt>
      # 
      # == Examples
      # 
      #   I18n.locale = :en
      #   I18n.backend.store_translations 'en', :i18n => { :inflections => {
      #                                                     :gender => {
      #                                                       :n => 'neuter',
      #                                                       :o => 'other',
      #                                                       :default => 'n' }}}
      #   
      #   I18n.backend.store_translations 'en', 'welcome'      => 'Dear @{n:You|o:Other}'
      #   I18n.backend.store_translations 'en', 'welcome_free' => 'Dear @{n:You|o:Other|Free}'
      #   
      # === Example 1
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
      #   I18n.t('welcome', :inflector_unknown_defaults => false)
      #   # => "Dear You"
      #   
      #   # :gender option is not present, free text is present,
      #   # unknown tokens from options are not falling back to default
      #   
      #   I18n.t('welcome_free', :inflector_unknown_defaults => false)
      #   # => "Dear You"
      #   
      # === Example 2
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
      #   I18n.t('welcome', :gender => nil, :inflector_unknown_defaults => false)
      #   # => "Dear "
      #   
      #   # :gender option is nil, free text is present
      #   # unknown tokens from options are not falling back to default token for a kind
      #   
      #   I18n.t('welcome_free', :gender => nil, :inflector_unknown_defaults => false)
      #   # => "Dear Free"
      # 
      # === Example 3
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
      #   I18n.t('welcome', :gender => :unknown_blabla, :inflector_unknown_defaults => false)
      #   # => "Dear "
      #   
      #   # :gender option is unknown, free text is present
      #   # unknown tokens from options are not falling back to default token for a kind
      #   
      #   I18n.t('welcome_free', :gender => :unknown_blabla, :inflector_unknown_defaults => false)
      #   # => "Dear Free"
      attr_writer :inflector_unknown_defaults

      # When this switch is set to +true+ then inflector falls back and uses the default
      # token for a kind if an option passed to the translate method matches some token
      # for that kind but that particular token is not included in a processed
      # pattern. This switch is by default set to +false+.
      # 
      # Local option +:inflector_excluded_defaults+ passed to translation method
      # overrides this setting.
      # 
      # === Short name
      # <tt>I18n::Inflector.excluded_defaults</tt>
      # 
      # == Example
      # 
      #   I18n.locale = :en
      #   I18n.backend.store_translations 'en', :i18n => { :inflections => {
      #                                                     :gender => {
      #                                                       :n => 'neuter',
      #                                                       :m => 'male',
      #                                                       :o => 'other',
      #                                                       :default => 'n' }}}
      #   
      #   I18n.backend.store_translations 'en', 'welcome' => 'Dear @{n:You|m:Sir}'
      #   
      #   p I18n.t('welcome', :gender => :o)
      #   # => "Dear "
      #   
      #   p I18n.t('welcome', :gender => :o, :inflector_excluded_defaults => true)
      #   # => "Dear You"
      attr_writer :inflector_excluded_defaults
      
      # This is a switch that enables extended error reporting. When it's enabled then
      # errors will be raised when unknown or empty token is present in pattern or in options.
      # This switch is by default set to +false+.
      # 
      # Local option +:inflector_raises+ passed to translation method overrides this setting.
      # 
      # === Short name
      # <tt>I18n::Inflector.inflector_raises</tt>
      attr_writer :inflector_raises

    end
  end
end
