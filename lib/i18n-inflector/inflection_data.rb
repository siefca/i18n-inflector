# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains class that is used to keep
# inflection data.

# @abstract This namespace is shared with I18n subsystem.
module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations for performing on them.
    class InflectionData < InflectionData_Strict

      # Initializes internal structures.
      # 
      # @param [Symbol,nil] locale the locale identifier for the object to be labeled with
      def initialize(locale=nil)
        @kinds      = Hash.new(false)
        @tokens     = Hash.new(DUMMY_TOKEN)
        @defaults   = Hash.new
        @locale     = locale
      end

      # Adds an alias (overwriting an existing alias).
      # 
      # @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #     (in case of bad or +nil+ names or non-existent targets)
      # @overload add_alias(name, target)
      #   Adds an alias (overwriting an existing alias).
      #   @param [Symbol] name the name of an alias
      #   @param [Symbol] target the target token for the given +alias+
      #   @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #     (in case of bad or +nil+ names or non-existent targets)
      # @overload add_alias(name, target, kind)
      #   Adds an alias (overwriting an existing alias) when the given
      #   +kind+ matches the kind of the given target.
      #   @param [Symbol] name the name of an alias
      #   @param [Symbol] target the target token for the given +alias+
      #   @param [Symbol] kind the optional kind of a taget
      #   @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #     (in case of bad or +nil+ names or non-existent targets)
      def add_alias(name, target, kind=nil)
        target  = target.to_s
        name    = name.to_s
        return false if (name.empty? || target.empty?)
        kind    = nil if kind.to_s.empty?
        name    = name.to_sym
        target  = target.to_sym
        t_kind  = get_kind(target)
        return false if (t_kind.nil? || (!kind.nil? && t_kind != kind))
        @tokens[name] = {}
        @tokens[name][:kind]        = kind
        @tokens[name][:target]      = target
        @tokens[name][:description] = @tokens[target][:description]
        true
      end

      # Adds a token (overwriting existing token).
      # 
      # @param [Symbol] token the name of a token to add
      # @param [Symbol] kind the kind of a token
      # @param [String] description the description of a token
      # @return [void]
      def add_token(token, kind, description)
        token = token.to_sym
        @tokens[token] = {}
        @tokens[token][:kind]         = kind.to_sym
        @tokens[token][:description]  = description.to_s
        @kinds[kind] = true
      end

      # Tests if the token is a true token.
      # 
      # @overload has_true_token?(token)
      #   Tests if the token is a true token.
      #   @param [Symbol] token the identifier of a token
      #   @return [Boolean] +true+ if the given +token+ is
      #     a token and not an alias, +false+ otherwise 
      # @overload has_true_token?(token, kind)
      #   Tests if the token is a true token.
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +token+ is
      #     a token and not an alias, and is a kind of
      #     the given kind, +false+ otherwise 
      def has_true_token?(token, kind=nil)
        o = @tokens[token]
        k = o[:kind]
        return false if (k.nil? || !o[:target].nil?)
        kind.nil? ? true : k == kind
      end

      # Tests if a token (or alias) is present.
      # 
      # @overload has_token(token)
      #   Tests if a token (or alias) is present.
      #   @param [Symbol] token the identifier of a token
      #   @return [Boolean] +true+ if the given +token+ 
      #     (which may be an alias) exists
      # @overload has_token(token, kind)
      #   Tests if a token (or alias) is present.
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given +token+ 
      #     (which may be an alias) exists and if kind of
      #     the given kind
      def has_token?(token, kind=nil)
        k = @tokens[token][:kind]
        kind.nil? ? !k.nil? : k == kind
      end

      # Tests if a kind exists.
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if the given +kind+ exists
      def has_kind?(kind)
        @kinds.has_key?(kind)
      end

      # Tests if a kind has a default token assigned.
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if there is a default
      #   token of the given kind
      def has_default_token?(kind)
        @defaults.has_key?(kind)
      end

      # Tests if a given alias is really an alias.
      # 
      # @overload has_alias?(alias_name)
      #   Tests if a given alias is really an alias.
      #   @param [Symbol] alias_name the identifier of an alias
      #   @return [Boolean] +true+ if the given alias is really an alias,
      #     +false+ otherwise
      # @overload has_alias?(alias_name, kind)
      #   Tests if a given alias is really an alias.
      #   @param [Symbol] alias_name the identifier of an alias
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Boolean] +true+ if the given alias is really an alias
      #     being a kind of the given kind, +false+ otherwise
      def has_alias?(alias_name, kind=nil)
        o = @tokens[alias_name]
        return false if o[:target].nil?
        kind.nil? ? true : o[:kind] == kind
      end

      # Reads the all the true tokens (not aliases).
      # 
      # @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_true_tokens(kind)
      #   Reads the all the true tokens (not aliases).
      #   @return [Hash] the true tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_true_tokens(kind)
      #   Reads the all the true tokens (not aliases).
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the true tokens of the given kind in a
      #     form of Hash (<tt>token => description</tt>)
      def get_true_tokens(kind=nil)
        tokens = @tokens.reject{|k,v| !v[:target].nil?}
        tokens = tokens.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        tokens.merge(tokens){|k,v| v[:description]}
      end

      # Reads the all the aliases.
      # 
      # @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      # @overload get_aliases(kind)
      #   Reads the all the aliases.
      #   @return [Hash] the aliases in a
      #     form of Hash (<tt>alias => target</tt>)
      # @overload get_aliases(kind)
      #   Reads the all the aliases.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the aliases of the given kind in a
      #     form of Hash (<tt>alias => target</tt>)
      def get_aliases(kind=nil)
        aliases = @tokens.reject{|k,v| v[:target].nil?}
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases.merge(aliases){|k,v| v[:target]}
      end

      # Reads the all the tokens in a way that it is possible to
      # distinguish true tokens from aliases.
      # 
      # @note True tokens have descriptions (String) and aliases
      #   have targets (Symbol) assigned.
      # @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      # @overload get_raw_tokens
      #   Reads the all the tokens.
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description|target</tt>)
      # @overload get_raw_tokens(kind)
      #   Reads the all the tokens.
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the tokens of the given kind in a
      #     form of Hash (<tt>token => description|target</tt>)
      def get_raw_tokens(kind=nil)
        get_true_tokens(kind).merge(get_aliases(kind))
      end

      # Reads the all the tokens (including aliases).
      # 
      # @note Use {get_raw_tokens} if you want to distinguish
      #   true tokens from aliases.
      # @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_raw_tokens(kind)
      #   Reads the all the tokens (including aliases).
      #   @return [Hash] the tokens in a
      #     form of Hash (<tt>token => description</tt>)
      # @overload get_raw_tokens(kind)
      #   Reads the all the tokens (including aliases).
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Hash] the tokens of the given kind in a
      #     form of Hash (<tt>token => description</tt>)
      def get_tokens(kind=nil)
        tokens = @tokens
        tokens = tokens.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        tokens.merge(tokens){|k,v| v[:description]}
      end

      # Gets a target token for the alias.
      # 
      # @param [Symbol] alias_name the identifier of an alias
      # @return [Symbol,nil] the token that the given alias points to
      #   or +nil+ if it isn't really an alias
      def get_target_for_alias(alias_name)
        @tokens[alias_name][:target]
      end

      # Gets a kind of the given token or alias.
      # 
      # @param [Symbol] token identifier of a token
      # @return [Symbol,nil] the kind of the given +token+
      #   or +nil+ if the token is unknown
      def get_kind(token, kind=nil)
        k = @tokens[token][:kind]
        return k if (kind.nil? || kind == k)
        nil
      end

      # Gets a true token for the given identifier.
      # 
      # @note If the given +token+ is really an alias it will
      #   be resolved and the real token pointed by that alias
      #   will be returned.
      # @overload get_true_token(token)
      #   Gets a true token for the given token identifier.
      #   @param [Symbol] token the identifier of a token
      #   @return [Symbol,nil] the true token for the given +token+
      #     or +nil+ if the token is unknown
      # @overload get_true_token(token, kind)
      #   Gets a true token for the given token identifier and the
      #     given kind.
      #   @param [Symbol] token the identifier of a token
      #   @param [Symbol] kind the identifier of a kind
      #   @return [Symbol,nil] the true token for the given +token+
      #     or +nil+ if the token is unknown or is not a kind of the
      #     given +kind+
      def get_true_token(token, kind=nil)
        o = @tokens[token]
        k = o[:kind]
        return nil if k.nil?
        r = (o[:target] || token)
        return r if kind.nil?
        k == kind ? r : nil
      end

      # Gets all known kinds.
      # 
      # @return [Array<Symbol>] an array containing all the known kinds
      def get_kinds
        @kinds.keys
      end

      # Reads the default token of a kind.
      # 
      # @note It will always return true token (not an alias).
      # @param [Symbol] kind the identifier of a kind
      # @return [Symbol,nil] the default token of the given +kind+
      #   or +nil+ if there is no default token set
      def get_default_token(kind)
        @defaults[kind]
      end

      # Gets a description of a token or alias.
      # 
      # @note If the token is really an alias it will resolve the alias first.
      # @param [Symbol] token the identifier of a token
      # @return [String,nil] the string containing description of the given
      #   token (which may be an alias) or +nil+ if the token is unknown
      def get_description(token)
        @tokens[token][:description]
      end

      # Test if the inflection data have no elements.
      # 
      # @return [Boolean] +true+ if the inflection data
      #   have no elements
      def empty?
        @tokens.empty?
      end

    end # InflectionData

  end
end
