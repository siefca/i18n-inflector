# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains class that is used to keep
# inflection data for strict kinds.

# @abstract This namespace is shared with I18n subsystem.
module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations for strict kinds and tokens assigned to them.
    # Methods in this class vary from methods from {I18n::Inflector::InflectionData}
    # in a way that +kind+ argument is usually required, not optional, since
    # managing strict kinds requires a kind of a token to be always known.
    class InflectionData_Strict

      # This constant contains a dummy hash for an empty token. It makes
      # chaining calls to internal data easier.
      DUMMY_TOKEN   = {:kind=>nil, :target=>nil, :description=>nil}.freeze

      # This constant contains a dummy hash of hashes for tokens collection.
      # It makes chaining calls to internal data easier.
      DUMMY_TOKENS  = Hash.new(DUMMY_TOKEN).freeze

      # This constant contains a dummy iterator for hash of hashes.
      # It makes chaining calls to internal data easier.
      DUMMY_T_LAZY  = LazyEnumerator.new(DUMMY_TOKENS).freeze

      # This constant contains a dummy hash. It makes
      # chaining calls to internal data easier.
      DUMMY_HASH    = Hash.new.freeze

      # Locale that this database works on.
      attr_reader :locale

      # Initializes internal structures.
      # 
      # @param [Symbol,nil] locale the locale identifier for
      #   the object to be labeled with
      def initialize(locale=nil)
        @tokens       = Hash.new(DUMMY_TOKENS)
        @lazy_tokens  = Hash.new(DUMMY_T_LAZY)
        @defaults     = Hash.new
        @locale       = locale
      end

      # Adds an alias (overwriting existing alias).
      # 
      # @param [Symbol] name the name of an alias
      # @param [Symbol] target the target token for the given +alias+
      # @return [Boolean] +true+ if everything went ok, +false+ otherwise
      #  (in case of bad names or non-existent targets)
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
      # @param [Symbol] kind the identifier of a kind
      # @param [String] description the description of a token
      # @return [void]
      def add_token(token, kind, description)
        token     = token.to_sym
        kind      = kind.to_sym
        kind_tree = @tokens[kind]
        if kind_tree.equal?(DUMMY_TOKENS)
          kind_tree = @tokens[kind] = Hash.new(DUMMY_TOKEN)
          @lazy_tokens[kind] = LazyEnumerator.new(kind_tree)
        end
        token = kind_tree[token] = {}
        token[:description] = description.to_s
      end

      # Sets the default token for a kind.
      # 
      # @param [Symbol] kind the kind to which the default
      #   token should be assigned
      # @param [Symbol] target the token to set
      # @return [void]
      def set_default_token(kind, target)
        @defaults[kind.to_sym] = target.to_sym
      end

      # Tests if a token is a true token.
      # 
      # @param [Symbol] token the identifier of a token
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if the given +token+ is
      #   a token and not an alias, and is a kind of
      #   the given kind, +false+ otherwise 
      def has_true_token?(token, kind)
        @tokens[kind].has_key?(token) && @tokens[kind][token][:target].nil?
      end

      # Tests if a token (or alias) is present.
      # 
      # @param [Symbol] token the identifier of a token
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if the given +token+ 
      #   (which may be an alias) exists and if kind of
      #   the given kind
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

      # Tests if the given alias is really an alias.
      # 
      # @param [Symbol] alias_name the identifier of an alias
      # @param [Symbol] kind the identifier of a kind
      # @return [Boolean] +true+ if the given alias is really an alias
      #   being a kind of the given kind, +false+ otherwise
      def has_alias?(alias_name, kind)
        not @tokens[kind][alias_name][:target].nil?
      end

      # Reads all the true tokens (not aliases).
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Hash] the true tokens of the given kind in a
      #   form of Hash (<tt>token => description</tt>)
      def get_true_tokens(kind)
        @lazy_tokens[kind].
        h_reject { |token,data| !data[:target].nil? }.
        h_map    { |token,data| data[:description]  }.
        to_h
      end

      # Reads all the aliases.
      # 
      # @param [Symbol] kind the identifier of a kind
      # @return [Hash] the aliases of the given kind in a
      #   form of Hash (<tt>alias => target</tt>)
      def get_aliases(kind)
        @lazy_tokens[kind].
        h_reject { |token,data| data[:target].nil?  }.
        h_map    { |token,data| data[:target]       }.
        to_h
      end

      # Reads all the tokens in a way that it is possible to
      # distinguish true tokens from aliases.
      # 
      # @note True tokens have descriptions (String) and aliases
      #   have targets (Symbol) assigned.
      # @param [Symbol] kind the identifier of a kind
      # @return [Hash] the tokens of the given kind in a
      #   form of Hash (<tt>token => description|target</tt>)
      def get_raw_tokens(kind)
        @lazy_tokens[kind].
        h_map { |token,data| data[:target] || data[:description] }.
        to_h
      end

      # Reads all the tokens (including aliases).
      # 
      # @note Use {#get_raw_tokens} if you want to distinguish
      #   true tokens from aliases.
      # @param [Symbol] kind the identifier of a kind
      # @return [Hash] the tokens of the given kind in a
      #   form of Hash (<tt>token => description</tt>)
      def get_tokens(kind)
        @lazy_tokens[kind].h_map{ |token,data| data[:description] }.to_h
      end

      # Gets a target token for the alias.
      # 
      # @param [Symbol] alias_name the identifier of an alias
      # @param [Symbol] kind the identifier of a kind
      # @return [Symbol,nil] the token that the given alias points to
      #   or +nil+ if it isn't really an alias
      def get_target_for_alias(alias_name, kind)
        @tokens[kind][alias_name][:target]
      end

      # Gets a kind of the given token or alias.
      # 
      # @note This method may be concidered dummy since there is a
      #   need to give the inflection kind, but it's here in order
      #   to preserve compatibility with the same method from
      #   {I18n::Inflector::InflectionData} which guesses the kind.
      # @param [Symbol] token identifier of a token
      # @param [Symbol] kind the identifier of a kind
      # @return [Symbol,nil] the kind of the given +token+
      #   or +nil+ if the token is unknown or is not of the given kind
      def get_kind(token, kind)
        @tokens[kind].has_key?(token) ? kind : nil
      end

      # Gets a true token for the given identifier.
      # 
      # @note If the given +token+ is really an alias it will
      #   be resolved and the real token pointed by that alias
      #   will be returned.
      # @param [Symbol] token the identifier of a token
      # @param [Symbol] kind the identifier of a kind
      # @return [Symbol,nil] the true token for the given +token+
      #   or +nil+ if the token is unknown or is not a kind of the
      #   given +kind+
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
      # @param [Symbol] kind the identifier of a kind
      # @return [String,nil] the string containing description of the given
      #   token (which may be an alias) or +nil+ if the token is unknown
      def get_description(token, kind)
        @tokens[kind][token][:description]
      end

    end # InflectionData_Strict

  end
end
