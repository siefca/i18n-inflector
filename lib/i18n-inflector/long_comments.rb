# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains inline documentation data
# that would make the file with code less readable
# if placed there.
# 

module I18n
  # @version 2.2
  # This module contains inflection classes and modules for enabling
  # the inflection support in I18n translations.
  # It is used by the module called {I18n::Backend::Inflector}
  # that overwrites the Simple backend translate method
  # so that it will interpolate additional inflection data present
  # in translations. That data may appear in *patterns*
  # contained within <tt>@{</tt> and <tt>}</tt> symbols. Each pattern
  # consist of *tokens* and respective *values*.
  # 
  # == Usage
  #   require 'i18-inflector'
  #   
  #   i18n.translate('welcome', :gender => :f)
  #   # => Dear Madam
  #   
  #   i18n.inflector.kinds
  #   # => [:gender]
  # 
  #   i18n.inflector.true_tokens.keys
  #   # => [:f, :m, :n]
  #
  # See the {file:EXAMPLES} for more information about real-life
  # usage of Inflector.
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
  # There are also so called <b>named patterns</b> that will be explained
  # later.
  # 
  # == Configuration
  # To recognize tokens present in patterns keys grouped
  # in the scope called +inflections+ for the given locale are used. For instance
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
  # Kind is also used to instruct {I18n::Backend::Inflector#translate} method which
  # token it should pick. This is done through options and
  # will be explained later.
  # 
  # There is also a class of kind called <b>strict kind</b> used by
  # named patterns; that will be explained later.
  # 
  # === Tokens
  # The token is an element of a pattern. Any pattern may have many tokens
  # of the same kind separated by vertical bars. Each token name used in a
  # pattern should end with colon sign. After this colon a value should
  # appear (or an empty string).
  # 
  # Tokens also appear in a configuration data. They are assigned to kinds.
  # Token names must be unique across all kinds, since it would be impossible
  # for interpolation routine to guess a kind of a token present in a pattern.
  # There is however a class of kinds called strict kinds, for which tokens
  # must be unique only within a kind. The named patterns that are using
  # strict kinds will be explained later.
  # 
  # === Aliases
  # Aliases are special tokens that point to other tokens. They cannot
  # be used in inflection patterns but they are fully recognized options
  # that can be passed to +translate+ method.
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
  # == Interpolation
  # The value of each token present in a pattern is to be picked by the interpolation
  # routine and will replace the whole pattern, when the token name from that
  # pattern matches the value of an option passed to {I18n.translate} method.
  # This option is called <b>the inflection option</b>. Its name should be
  # the same as a *kind* of tokens used within a pattern. The first token in a pattern
  # determines the kind of all tokens used in that pattern. You can pass
  # many inflection options, each one designated for keeping a token of a
  # different kind.
  # 
  # === Examples:
  # 
  # ===== YAML:
  # Let's assume that the translation data in YAML format listed
  # below is used in any later example, unless other inflections
  # are given.
  #   en:
  #     i18n:
  #       inflections:
  #         gender:
  #           m:       "male"
  #           f:       "female"
  #           n:       "neuter"
  #           default: n
  #   
  #     welcome:  "Dear @{f:Madam|m:Sir|n:You|All}"
  # ===== Code:
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
  # === Local fallbacks (free text)
  # The fallback value will be used when any of the given tokens from
  # pattern cannot be interpolated.
  # 
  # Be aware that enabling extended error reporting makes it unable
  # to use fallback values in most cases. Local fallbacks will then be
  # applied only when the given option contains a proper value for some
  # kind but it's just not present in a pattern, for example:
  # 
  # ===== YAML:
  #   en:
  #     i18n:
  #       inflections:
  #         gender:
  #           n:    'neuter'
  #           o:    'other'
  #       
  #     welcome:    "Dear @{n:You|All}"
  # 
  # ===== Code:
  #   I18n.translate('welcome', :gender => :o, :inflector_raises => true)
  #   # => "Dear All"
  #   # since the token :o was configured but not used in the pattern
  # 
  # === Unknown, malformed and empty tokens in options
  # If an option containing token is not present at all then the interpolation
  # routine will try the default token for a processed kind if the default
  # token is present in a pattern. The same thing will happend if the option
  # is present but its value is malformed, unknown, empty or +nil+.
  # If the default token is not present in a pattern or is not defined in
  # a configuration data then the processing of a pattern will result
  # in an empty string or in a local fallback value if there is
  # a free text placed in a pattern.
  # 
  # You can change this default behavior and force inflector
  # not to use a default token when a value of an option for
  # a kind is malformed, unknown, empty or +nil+ but only when
  # it's not present. To do that you should set option +:inflector_unknown_defaults+
  # to +false+ and pass it to I18n.translate method. Other way is to set this
  # switch globally using the {I18n::Inflector::InflectionOptions#unknown_defaults}.
  # 
  # === Unmatched tokens in options
  # It might happend that there is a default token present in a pattern
  # but the inflection option causes other token to be picked up
  # which however is not present in this pattern although it's
  # correct and assigned to the currently processed kind. In such
  # situation the free text or an empty string will be generated.
  # You may change that behavior by passing +:inflector_excluded_defaults+
  # option set to +true+ or by setting the global option called
  # {I18n::Inflector::InflectionOptions#excluded_defaults}. If this
  # option is set then any unmatched (excluded) but correct token
  # given in an inflection option will cause the default token
  # to be picked up (if present in a pattern of course).
  # 
  # === Mixing inflection and standard interpolation patterns
  # The Inflector module allows you to include standard <tt>%{}</tt>
  # patterns inside of inflection patterns. The value of a standard
  # interpolation variable will be evaluated and interpolated *before*
  # processing an inflection pattern. For example:
  # 
  # ===== YAML:
  # Note: <em>Uses inflection configuration given in the first example.</em> 
  #   en:
  #     hi:   "Dear @{f:Lady|m:%{test}}!"
  # ===== Code:
  #   I18n.t('hi', :gender => :m, :locale => :xx, :test => "Dude")
  #   # => Dear Dude!
  # 
  # === Token groups
  # It is possible to assign some value to more than one token.
  # You can create group of tokens by separating them using commas.
  # The comma has the meaning of logical OR in such a token group.
  # 
  # ===== YAML:
  # Note: <em>Uses inflection configuration given in the first example.</em> 
  #   en:
  #     welcome:  "Hello @{m,f:Ladies and Gentlemen|n:You}!"
  # ===== Code:
  #   I18n.t('welcome', :gender => :f)
  #   # => Hello Ladies and Gentlemen!
  # 
  # === Inverse matching of tokens
  # You can place exclamation mark before a token that should be
  # matched negatively. It's value will be used for a pattern
  # <b>if the given inflection option contains other token</b>.
  # You can use inversed matching tokens in token groups but
  # note that using more than one inversed token separated
  # by a comma will cause the expression to mach every time.
  # 
  # ===== YAML:
  # Note: <em>Uses inflection configuration given in the first example.</em> 
  #   en:
  #     welcome:  "Hello @{!m:Ladies|n:You}!"
  # 
  # ===== Code:
  #   I18n.t('welcome', :gender => :n)
  #   # => Hello Ladies!
  #   
  #   I18n.t('welcome', :gender => :f)
  #   # => Hello Ladies!
  #   
  #   I18n.t('welcome', :gender => :m)
  #   # => Hello !
  # 
  # === Loud tokens
  # Sometimes there might be a need to use descriptions of
  # matching tokens instead of some given values. Use <b>loud tokens</b>
  # to achieve that. Any matching token in a pattern that has tilde symbol (+~+)
  # set as its value will be replaced by its description. In case of
  # undescribed aliases, the description from a target token will be used.
  # 
  # ===== YAML:
  # Note: <em>Uses inflection configuration given in the first example.</em> 
  #   en:
  #     welcome:  "Hello @{m:~|n:~}!"
  # 
  # ===== Code:
  #   I18n.t('welcome', :gender => :n)
  #   # => Hello neuter!
  #   
  #   I18n.t('welcome', :gender => :f)
  #   # => Hello female!
  # 
  # To use tilde symbol as the only value of a token you may esape it
  # by putting a backslash in front of the symbol.
  # 
  # === Aliases in a pattern
  # Normally it is possible to use only true tokens in patterns, not aliases.
  # However, if you feel lucky and you're not affraid of messy patterns
  # you can use the switch {I18n::Inflector::InflectionOptions#aliased_patterns}
  # or corresponding +:inflector_aliased_patterns+ option passed to translation
  # method.
  # 
  # It may seem very easy and attractive to use aliased patterns, especially
  # in the environments where token comes from a user. In such cases aliases
  # may be used as database that translates common words to inflection tokens
  # that have meanings. For example user may enter a gender in some text
  # field and it will be used as inflection token. To map different names
  # (e.g. male, boy, sir, female, girl, lady) to exact inflection tokens
  # the aliases would be used. Note hovewer, that you can make use of
  # <tt>I18n.inflector.true_token</tt> method (see {I18n::Inflector::API#true_token}
  # that will resolve any alias and then use that data to feed some inflection option
  # (e.g. +:gender+). In such scenario you don't have to rely on aliases
  # in patterns and you will gain some speed since resolving will occur just once,
  # not each time translated text is interpolated.
  # 
  # === Escaping a pattern
  # If there is a need to translate something that matches an inflection
  # pattern the escape symbols can be used to disable the interpolation. These
  # symbols are <tt>\\</tt> and +@+ and they should be placed just before
  # a pattern that should be left untouched. For instance:
  # 
  # ===== YAML:
  # Note: <em>Uses inflection configuration given in the first example.</em> 
  #   en:
  #     welcome:  "This is the @@{pattern}!"
  # ===== Code:
  #   I18n.t('welcome', :gender => :m, :locale => :xx)
  #   # => This is the @{pattern}!
  # 
  # == Named patterns
  # 
  # A named pattern is a pattern that contains name of a kind
  # that tokens from a pattern are assigned to. It looks like:
  # 
  #   welcome: "Dear @gender{f:Madam|m:Sir|n:You|All}"
  # 
  # === Configuring named patterns
  # To recognize tokens present in named patterns,
  # inflector uses keys grouped in the scope called +inflections+
  # for the given locale. For instance (YAML format):
  #   en:
  #     i18n:
  #       inflections:
  #         @gender:
  #           f:      "female"
  #           woman:  @f
  #           default: f
  # 
  # Elements in the example above are:
  # * +en+: language
  # * +i18n+: configuration scope
  # * +inflections+: inflections configuration scope
  # * +gender+: <bb>strict kind</bb> scope
  # * +f+: inflection token
  # * <tt>"female"</tt>: token's description
  # * +woman+: inflection alias
  # * <tt>@f</tt>: pointer to real token
  # * +default+: default token for a strict kind +gender+
  # 
  # === Strict kinds
  # 
  # In order to handle named patterns properly a new data structure
  # is used. It is called the <b>strict kind</b>. Strict kinds are defined
  # in a configuration in a similar way the regular kinds are but
  # tokens assigned to them may have the same names across a whole
  # configuration. (Note that tokens of the same strict kind should still
  # be unique.) That implies a requirement of passing the
  # identifier of a kind when referring to such tokens.
  # 
  # Here is the example configuration using strict kinds:
  # 
  #   en:
  #     i18n:
  #       inflections:
  #         @gender:
  #           f:      "female"
  #           m:      "male"
  #           n:      "neuter"
  #           woman:  @f
  #           man:    @m
  #           default: n
  #         @title:
  #           s:      "sir"
  #           l:      "lady"
  #           u:      "you"
  #           m:      @s
  #           f:      @l
  #           default: u
  # 
  # The only thing that syntactically distinguishes strict kinds
  # from regular kinds is a presence of the +@+ symbol.
  # 
  # You can mix regular and strict kinds having the same names.
  # The proper class of kind will be picked up by interpolation
  # method easily, since the first mentioned class uses
  # patterns that are not named, and the second uses named patterns.
  # 
  # ==== Strict kinds in options
  # 
  # The interpolation routine recognizes strict kinds passed as
  # options in almost the same way that it does it for regular
  # kinds. The only difference is that you can override usage
  # of a regular kind inflection option (if there is any) by
  # putting a strict kind option with name prefixed by +@+ symbol.
  # The inflection options starting with this symbol have
  # precedence over inflection options without it;
  # that is of course only true for strict kinds and has any effect
  # only when both options describing the same kind are present.
  # 
  # In other words: interpolation routine is looking for
  # strict kinds in inflection options using their names
  # with +@+ in front. When that fails it falls back to
  # trying an option named like the strict kind but without
  # the +@+ symbol. Examples:
  # 
  #  I18n.translate(welcome, :gender => :m, :@gender => :f)
  #  # the :f will be picked for the strict kind gender
  #  
  #  I18n.translate(welcome, :@gender => :f)
  #  # the :f will be picked for the strict kind gender
  #  
  #  I18n.translate(welcome, :gender => :f)
  #  # the :f will be picked for the strict kind gender
  # 
  # In the example above we assume that +welcome+ is defined
  # like that:
  # 
  #   welcome: "Dear @gender{f:Madam|m:Sir|n:You|All}"
  # 
  # Note that for regular kinds the option named +:@gender+
  # will have no meaning.
  # 
  # ==== Note for developers
  # 
  # Strict kinds that are used to handle named patterns
  # are internally stored in a different database and handled by
  # similar but different API methods than regular kinds. However
  # most of the {I18n::Inflector::API} methods are also aware of strict kinds
  # and will call proper methods oprating on strict inflections
  # data when the +@+ symbol is detected at the beginning of
  # the identifier of a kind passed as an argument. For example:
  # 
  #   I18n.inflector.has_token?(:m, :@gender)
  # 
  # will effectively call:
  # 
  #  I18n.inflector.strict.has_token?(:m, :gender)
  # 
  # As you can see above, to access {API_Strict} methods for strict kinds
  # (and strict kinds data) only, associated with default I18n backend,
  # use:
  # 
  #   I18n.inflector.strict
  # 
  # == Complex patterns
  # 
  # A <bb>complex pattern</bb> is a named pattern that uses more than
  # one inflection kind and sets of a respective tokens. The given identifiers
  # of kinds should be separated by the plus sign and instead of single
  # tokens there should be token sets (a tokens separated by the plus
  # sign too).
  # 
  # Example:
  # 
  #   welcome:  "Dear @gender+number{f+s:Lady|f+p:Ladies|m+s:Sir|m+p:Gentlemen|All}"
  # 
  # In the example above the complex pattern uses +gender+ and +number+
  # inflection kinds and a token set (e.g. <tt>f+s</tt>) matches when
  # both tokens match interpolation options (e.g. <tt>:gender => :f</tt>,
  # <tt>:number => :s</tt>). The order of tokens in sets has meaning
  # and should reflect the order of declared kinds.
  # 
  # Note, that the count of tokens in each set should reflect the count
  # of kinds that are used. Otherwise the interpolation routine will
  # interpolate a free text (if given) or an empty string. If the switch
  # {InflectionOptions#raises} is on then the {I18n::ComplexPatternMalformed}
  # exception will be raised in such a case.
  # 
  # The inflection tokens used in sets may make use of any features mentioned
  # before (defaults, excluded defaults, negative matching, token groups,
  # aliases, aliased patterns, loud tokens).
  # 
  # === Loud tokens in complex patterns
  # 
  # In case of loud tokens (having values taken from their
  # descriptions), the complex pattern will be replaced by
  # the descriptions of matching tokens joined with a single space
  # character. So, for instance, when the translation data looks like:
  # 
  #   i18n:
  #     inflections:
  #       @person:
  #         i: 'I'
  #         u: 'You'
  #       @tense:
  #         now:  'am'
  #         past: 'were'
  #   welcome: "@person+tense{i+now:~|u+past:~}"
  # 
  # the translate method will give the following results:
  # 
  #   I18n.translate('welcome', :person => :i, :tense => :now)
  #   # => "I am"
  # 
  #   I18n.translate('welcome', :person => :you, :tense => :past)
  #   # => "You were"
  # 
  # This example is abstract, since the combination of +:i+
  # and +:past+ will result in <tt>i were</tt> string, which is
  # probably something unexpected. To achieve that kind of logic
  # simply use combined patterns with the given values instead
  # of loud tokens.
  # 
  # == Reserved names
  # Some strings cannot be used as names and/or identifiers of
  # kinds and tokens. There are also some reserved characters
  # that cannot be used within them.
  # 
  # == Operator precedence
  # symbol - meaning - defined in
  # == Errors
  # By default the module will silently ignore non-critical interpolation
  # errors. You can turn off this default behavior by passing +:inflector_raises+
  # option set to +true+.
  #
  # === Usage of +:inflector_raises+ option
  # 
  # ===== YAML
  # Note: <em>Uses inflection configuration given in the first example.</em> 
  #   en:
  #     welcome:  "Dear @{m:Sir|f:Madam|Fallback}"
  # ===== Code:
  #   I18n.t('welcome', :inflector_raises => true)
  #   # => I18n::InflectionOptionNotFound: en.welcome:
  #   #      @{m:Sir|f:Madam|Fallback}" - required option :gender was not found
  # 
  # === Exception meanings
  # Here are the exceptions that may be raised when the option +:inflector_raises+
  # is set to +true+:
  # 
  # * {I18n::InvalidInflectionToken I18n::InvalidInflectionToken}
  # * {I18n::InvalidInflectionKind I18n::InvalidInflectionKind}
  # * {I18n::InvalidInflectionOption I18n::InvalidInflectionOption}
  # * {I18n::MisplacedInflectionToken I18n::MisplacedInflectionToken}
  # * {I18n::InflectionOptionNotFound I18n::InflectionOptionNotFound}
  # * {I18n::InflectionOptionIncorrect I18n::InflectionOptionIncorrect}
  # * {I18n::ComplexPatternMalformed I18n::ComplexPatternMalformed}
  # 
  # There are also exceptions that are raised regardless of :+raises+
  # presence or value.
  # These are usually caused by critical errors encountered during processing
  # inflection data or exceptions raised by I18n. Note that the pure I18n's
  # exceptions are not described here.
  # 
  # * {I18n::ArgumentError I18n::ArgumentError}
  # * {I18n::InvalidLocale I18n::InvalidLocale}
  # * {I18n::DuplicatedInflectionToken I18n::DuplicatedInflectionToken}
  # * {I18n::BadInflectionKind I18n::BadInflectionKind}
  # * {I18n::BadInflectionToken I18n::BadInflectionToken}
  # * {I18n::BadInflectionAlias I18n::BadInflectionAlias}
  # 
  # === Exception hierarchy
  #   I18n::ArgumentError
  #   |
  #   `-- I18n::InvalidLocale
  #   |
  #   `-- I18n::InflectionException
  #       |
  #       `-- I18n::InflectionPatternException
  #       |   |
  #       |   |-- I18n::InvalidInflectionToken
  #       |   |-- I18n::InvalidInflectionKind
  #       |   |-- I18n::MisplacedInflectionToken
  #       |   |-- I18n::ComplexPatternMalformed
  #       |   `-- I18n::InvalidOptionForKind
  #       |       |-- I18n::InflectionOptionNotFound
  #       |       `-- I18n::InflectionOptionIncorrect
  #       |
  #       `-- I18n::InflectionConfigurationException
  #           |
  #           |-- I18n::DuplicatedInflectionToken
  #           |-- I18n::BadInflectionAlias
  #           |-- I18n::BadInflectionToken
  #           `-- I18n::BadInflectionKind
  # 
  module Inflector

    class API

      # This reader allows to reach a reference of the
      # object that is a kind of {I18n::Inflector::API_Strict}
      # and handles inflections for named patterns (strict kinds).
      # 
      # @api public
      # @return [I18n::Inflector::API_Strict] the object containing
      #   database and operations for named patterns (strict kinds)
      attr_reader :strict

      # This reader allows to reach internal configuration
      # of the engine. It is shared among all instances of
      # the Inflector and also available as
      # {I18n::Inflector::Config I18n::Inflector::Config}.
      attr_reader :config

      # Gets known regular inflection kinds.
      # 
      # @api public
      # @note To get all inflection kinds (regular and strict) for default inflector
      #   use: <tt>I18n.inflector.kinds + I18n.inflector.strict.kinds</tt>
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
        super
      end
      alias_method :inflection_kinds, :kinds

    end

  end

  # @abstract This exception class is defined in package I18n. It is raised when
  #   the given and/or processed locale parameter is invalid.
  class InvalidLocale; end

  # @abstract This exception class is defined in package I18n. It is raised when
  #   the given and/or processed translation data or parameter are invalid.
  class ArgumentError; end

end
