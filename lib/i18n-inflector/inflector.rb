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
    # @return [I18n::Inflector::API] inflector the inflector
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
      return RESERVED_KEYS                        if defined?(RESERVED_KEYS)
      []
    end
    module_function :get_reserved_keys

    # Contains <tt>@</tt> string that is used to quickly fallback
    # to standard +translate+ method if it's not found.
    PATTERN_MARKER  = '@'

    # Contains a regular expression that catches patterns.
    PATTERN         = /(.?)@([^\{]*)\{([^\}]+)\}/

    # Contains a regular expression that catches tokens.
    TOKENS          = /(?:([^\:\|]+):+([^\|]+)\1?)|([^:\|]+)/

    # Contains a symbol that indicates a named pattern.
    NAMED_MARKER    = '@'

    # Contains a symbol used to mark patterns as complex.
    COMPLEX_MARKER = '+'

    # Conatins a symbol used to separate multiple tokens.
    OPERATOR_MULTI  = ','

    # Conatins a symbol used to mark tokens as negative.
    OPERATOR_NOT    = '!'

    # Contains a symbol that indicates an alias.
    ALIAS_MARKER    = '@'

    # Conatins a symbol used to mark tokens as loud.
    LOUD_MARKER     = '~'

    # Contains a general esape symbol.
    ESCAPE          = '\\'

    # Contains a regular expression that catches escape symbols.
    ESCAPE_R        = /\\([^\\])/

    # Contains a list of escape symbols that cause a pattern to be escaped.
    ESCAPES         = HSet['@', '\\']

    # Max. number of patterns to keep in cache.
    CACHE_SIZE      = 128

    # Max. number of variants of patterns (created by different options).
    CACHE_VAR       = 3

    # Reserved keys
    INFLECTOR_RESERVED_KEYS = I18n::Inflector.get_reserved_keys

  end # module Inflector

end # module I18n
