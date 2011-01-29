# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains error reporting classes for I18n::Backend::Inflector module.

module I18n

  # @abstract It is a parent class for all exceptions
  #   related to inflections.
  class InflectionException < ArgumentError
  end

  # @abstract It is a parent class for all exceptions
  #   related to inflection patterns that are processed.
  class InflectionPatternException < InflectionException

    attr_reader :pattern
    attr_reader :token
    attr_reader :kind

    def initialize(*args)
      @pattern  ||= nil
      @token    ||= nil
      @kind     ||= nil
      super
    end

  end

  # @abstract It is a parent class for all exceptions
  #   related to configuration data of inflections that is processed.
  class InflectionConfigurationException < InflectionException

    attr_reader :token
    attr_reader :kind

    def initialize(*args)
      @token  ||= nil
      @kind   ||= nil
      super
    end

  end

  # @abstract It is a parent class for exceptions raised when
  #   inflection option is bad or missing.
  class InvalidOptionForKind < InflectionPatternException

    attr_reader :option

    def initialize(pattern, kind, token, option)
      @pattern, @kind, @token, @option, @option_present = pattern, kind, token, option
      @message ||= ""
      super(@message)
    end

  end

  # This is raised when there is no kind given in options. The kind
  # is determined by looking at token placed in a pattern.
  class InflectionOptionNotFound < InvalidOptionForKind

    def initialize(pattern, kind, token, option=nil)
      kind = kind.to_s
      unless kind.empty?
        if kind[0..0] == I18n::Inflector::NAMED_MARKER
          kind = ":#{kind} (or :#{kind[1..-1]})"
        else
          kind = kind.to_sym.inspect
        end
      end
      @message = "option #{kind} required by the " +
                 "pattern #{pattern.inspect} was not found"  
      super
    end

  end

  # This exception will be raised when a required option, describing token selected
  # for a kind, is +nil+, empty or doesn't match any acceptable tokens.
  class InflectionOptionIncorrect < InvalidOptionForKind

    def initialize(pattern, kind, token, option)
      @message = "value #{option.inspect} of option #{kind.inspect} required by " +
                 "#{pattern.inspect} does not match any token"
      super
    end

  end

  # This is raised when token given in pattern is invalid (empty or has no
  # kind assigned).
  class InvalidInflectionToken < InflectionPatternException
    def initialize(pattern, token, kind=nil)
      @pattern, @token, @kind = pattern, token, kind
      super "token #{token.inspect} used in translation " + 
            "pattern #{pattern.inspect} is invalid"
    end

  end

  # This is raised when an inflection token used in a pattern does not match
  # an assumed kind determined by reading previous tokens from that pattern.
  class MisplacedInflectionToken < InflectionPatternException

    def initialize(pattern, token, kind)
      @pattern, @token, @kind = pattern, token, kind
      super "inflection token #{token.inspect} from pattern #{pattern.inspect} " +
            "is not of the expected kind #{kind.inspect}"
    end

  end

  # This is raised when an inflection token of the same name is already defined in
  # inflections tree of translation data.
  class DuplicatedInflectionToken < InflectionConfigurationException

    attr_reader :original_kind

    def initialize(original_kind, kind, token)
      @original_kind, @kind, @token = original_kind, kind, token
      and_cannot = kind.nil? ? "" : "and cannot be used with kind #{kind.inspect}"
      super "inflection token #{token.inspect} was already assigned " +
            "to kind #{original_kind} " + and_cannot
    end

  end

  # This is raised when an alias for an inflection token points to a token that
  # doesn't exists. It is also raised when default token of some kind points
  # to a non-existent token.
  class BadInflectionAlias < InflectionConfigurationException

    attr_reader :locale, :pointer

    def initialize(locale, token, kind, pointer)
      @locale, @token, @kind, @pointer = locale, token, kind, pointer
      what = token == :default ? "default token" : "alias"
      lang = locale.nil? ? "" : "for language #{locale.inspect} "
      kinn = kind.nil? ?   "" : "of kind #{kind.inspect} "
      super "the #{what} #{token.inspect} " + kinn + lang +
            "points to an unknown token #{pointer.inspect}"
    end

  end

  # This is raised when an inflection token or its description has a bad name. This
  # includes an empty name or a name containing prohibited characters.
  class BadInflectionToken < InflectionConfigurationException

    attr_reader :locale, :description

    def initialize(locale, token, kind=nil, description=nil)
      @locale, @token, @kind, @description = locale, token, kind, description
      kinn = kind.nil? ? "" : "of kind #{kind.inspect} "
      if description.nil?
        super "Inflection token #{token.inspect} " + kinn +
              "for language #{locale.inspect} has a bad name"
      else
        super "Inflection token #{token.inspect} " + kinn +
              "for language #{locale.inspect} has a bad description #{description.inspect}"
      end
    end

  end

end
