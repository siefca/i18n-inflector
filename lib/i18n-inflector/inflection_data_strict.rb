# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains class that is used to keep
# inflection data for named patterns.

# @abstract This namespace is shared with I18n subsystem.
module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations for performing on them for named patterns.
    class InflectionData::Strict < InflectionData

      class <<self

        def dummy_tokens
          @dummy_tokens ||= Hash.new(@dummy_token).freeze
        end # contant is better

      end

      # Initializes internal structures.
      def initialize(locale=nil)
        @dummy_token  = self.class.dummy_token
        @dummy_tokens = self.class.dummy_tokens
        @dummy_hash   = self.class.dummy_hash
        @tokens       = Hash.new(@dummy_tokens)
        @defaults     = Hash.new
        @locale       = locale
      end

      # Adds an alias (overwriting existing alias).
      # 
      # @param [Symbol] name the name of an alias
      # @param [Symbol] target the target token for the given +alias+
      # @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #  (in case of bad or +nil+ names or non-existent targets)
      def add_alias(name, target, kind)
        return false if (name.to_s.empty? || target.to_s.empty? || kind.to_s.empty?)
        name    = name.to_sym
        target  = target.to_sym
        kind    = kind.to_sym
        k       = @tokens[kind]
        return false unless k.has_key?(target)
        token               = k[name] = {}
        token[:description] = k[target][:description]
        token[:target]      = target
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
        kind  = kind.to_sym
        @tokens[kind] = Hash.new(@dummy_token) unless @tokens.has_key?(kind)
        token = @tokens[kind][token] = {}
        token[:description] = description.to_s
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
      def has_true_token?(token, kind)
        @tokens[kind].has_key?(token) && @tokens[kind][token][:target].nil?
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
      def has_token?(token, kind)
       @tokens[kind].has_key?(token)
      end

      # Tests if a kind exists.
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if the given +kind+ exists
      def has_kind?(kind)
        @tokens.has_key?(kind)
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
      def has_alias?(alias_name, kind)
        not @tokens[kind][alias_name][:target].nil?
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
      def get_true_tokens(kind)
        tokens = @tokens[kind].reject{|k,v| !v[:target].nil?}
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
      def get_aliases(kind)
        aliases = @tokens[kind].reject{|k,v| v[:target].nil?}
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
      def get_raw_tokens(kind)
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
      def get_tokens(kind)
        tokens = @tokens[kind]
        tokens.merge(tokens){|k,v| v[:description]}
      end

      # Gets a target token for the alias.
      # 
      # @param [Symbol] alias_name the identifier of an alias
      # @return [Symbol,nil] the token that the given alias points to
      #   or +nil+ if it isn't really an alias
      def get_target_for_alias(alias_name, kind)
        @tokens[kind][alias_name][:target]
      end

      # Gets a kind of the given token or alias.
      # 
      # @param [Symbol] token identifier of a token
      # @return [Symbol,nil] the kind of the given +token+
      #   or +nil+ if the token is unknown
      def get_kind(token, kind)
        @tokens[kind].has_key?(token) ? kind : nil
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
      #     or +nil+ if the token is unknown or is not kind of the
      #     given kind
      def get_true_token(token, kind)
        o = @tokens[kind]
        return nil unless o.has_key?(token)
        o = o[token]
        o[:target].nil? ? token : o[:target]
      end

      # Gets all known kinds.
      # 
      # @return [Array<Symbol>] an array containing all the known kinds
      def get_kinds
        @tokens.keys
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
      def get_description(token, kind)
        @tokens[kind][token][:description]
      end

      # This method validates default tokens assigned
      # for kinds and replaces targets with true tokens
      # if they are aliases.
      # 
      # @return [nil,Array<Symbol>] +nil+ if everything went fine,
      #   two dimensional array containing kind and target
      #   in case of error while geting a token
      def validate_default_tokens
        @defaults.each do |kind, pointer|
          ttok = get_true_token(pointer, kind)
          return [kind, pointer] if ttok.nil?
          set_default_token(kind, ttok) 
        end
        return nil
      end

    end # InflectionData::Strict

  end
end
