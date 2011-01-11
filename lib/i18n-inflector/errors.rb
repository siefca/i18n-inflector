# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains error reporting classes for I18n::Backend::Inflector module.

module I18n

  # This is raised when there is no kind given in options or the kind is +nil+. The kind
  # is determined by looking at token placed in a pattern.
  # 
  # This exception will also be raised when a required option, describing token selected
  # for a kind, is empty or doesn't match any acceptable tokens.
  class InvalidOptionForKind < ArgumentError
    attr_reader :pattern, :kind, :token, :option
    def initialize(pattern, kind, token, option)
      @pattern, @kind, @token, @option = pattern, kind, token, option
      if option.nil?
        super "option #{kind.inspect} required by the " +
              "pattern #{pattern.inspect} was not found"
      else
        super "value #{option.inspect} of #{kind.inspect} required by the " +
              "pattern #{pattern.inspect} does not match any token"      
      end
    end
  end

  # This is raised when token given in pattern is invalid (empty or has no
  # kind assigned).
  class InvalidInflectionToken < ArgumentError
    attr_reader :pattern, :token
    def initialize(pattern, token)
      @pattern, @token = pattern, token
      super "token #{token.inspect} used in translation " + 
            "pattern #{pattern.inspect} is invalid"
    end
  end
  
  # This is raised when an inflection token used in a pattern does not match
  # an assumed kind determined by reading previous tokens from that pattern.
  class MisplacedInflectionToken < ArgumentError
    attr_reader :pattern, :token, :kind
    def initialize(pattern, token, kind)
      @pattern, @token, @kind = pattern, token, kind
      super "inflection token #{token.inspect} from pattern #{pattern.inspect} " +
            "is not of the expected kind #{kind.inspect}"
    end
  end

  # This is raised when an inflection token of the same name is already defined in
  # inflections tree of translation data.
  class DuplicatedInflectionToken < ArgumentError
    attr_reader :original_kind, :kind, :token
    def initialize(original_kind, kind, token)
      @original_kind, @kind, @token = original_kind, kind, token
      and_cannot = kind.nil? ? "" : "and cannot be used with kind #{kind.inspect}"
      super "inflection token #{token.inspect} was already assigned " +
            "to kind #{original_kind}" + and_cannot
    end
  end

  # This is raised when an alias for an inflection token points to a token that
  # doesn't exists. It is also raised when default token of some kind points
  # to a non-existent token.
  class BadInflectionAlias < ArgumentError
    attr_reader :locale, :token, :kind, :pointer
    def initialize(locale, token, kind, pointer)
      @locale, @token, @kind, @pointer = locale, token, kind, pointer
      what = token == :default ? "default token" : "alias"
      super "the #{what} #{token.inspect} of kind #{kind.inspect} " +
            "for language #{locale.inspect} points to an unknown token #{pointer.inspect}"
    end
  end
  
  # This is raised when an inflection token or its description has a bad name. This
  # includes an empty name or a name containing prohibited characters.
  class BadInflectionToken < ArgumentError
    attr_reader :locale, :token, :kind, :description
    def initialize(locale, token, kind, description=nil)
      @locale, @token, @kind, @description = locale, token, kind, description
      if description.nil?
        super "Inflection token #{token.inspect} of kind #{kind.inspect} "+
              "for language #{locale.inspect} has a bad name"
      else
        super "Inflection token #{token.inspect} of kind #{kind.inspect} "+
              "for language #{locale.inspect} has a bad description #{description.inspect}"
      end
    end
  end

end
