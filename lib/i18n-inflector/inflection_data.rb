# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains utility methods,
# that are used by I18n::Inflector and I18n::Backend::Inflector.

module I18n
  module Inflector

    class InflectionData

      def initialize
        @kinds    = Hash.new(false)
        @tokens   = {}
        @defaults = {}
      end

      def add_alias(name, target)
        target  = target.to_s
        name    = name.to_s
        raise I18n::BadInflectionToken.new(nil, token, nil) if (name.empty? || target.empty?)
        name    = name.to_sym
        target  = target.to_sym
        kind    = get_kind(target)
        raise BadInflectionAlias.new(nil, name, kind, target) if kind.nil?
        @tokens[name] = {}
        @tokens[name][:kind]         = kind
        @tokens[name][:target]       = target
        @tokens[name][:description]  = @tokens[target][:description]
      end

      def add_token(token, kind, description)
        token = token.to_sym
        @tokens[token] = {}
        @tokens[token][:kind]         = kind.to_sym
        @tokens[token][:description]  = description.to_s
        @kinds[kind] = true
      end

      def set_default_token(kind, target)
        @defaults[kind.to_sym] = target.to_sym
      end

      def get_default_token(kind)
        @defaults[kind]
      end

      def has_true_token?(token)
        @tokens.has_key?(token) && @tokens[token][:target].nil?
      end

      def has_token?(token)
        @tokens.has_key?(token)
      end
      
      def has_kind?(kind)
        @kinds.has_key?(kind)
      end

      def get_kinds
        @kinds.keys
      end

      def get_description(token)
        @tokens.has_key?(token) ? @tokens[token][:description] : nil
      end

      def has_default_token?(kind)
        @defaults.has_key?(kind)
      end

      def get_kind(token)
        @tokens.has_key?(token) ? @tokens[token][:kind] : nil
      end

      def get_token(token)
        @tokens[token]
      end

      def get_true_token(token)
        return nil unless @tokens.has_key?(token)
        return @tokens[token][:target] || token
      end

      def has_alias?(token)
        @tokens.has_key?(token) && !@tokens[token][:target].nil?
      end

      def get_target_for_alias(alias_name)
        @tokens.has_key?(alias_name) ? @tokens[alias_name][:target] : nil
      end

      def validate_default_tokens
        @defaults.each_pair do |kind, pointer|
          ttok = get_true_token(pointer)
          raise I18n::BadInflectionAlias.new(nil, :default, kind, pointer) if ttok.nil?
          set_default_token(kind, ttok) 
        end
      end

      def get_true_tokens(kind=nil)
        tokens = @tokens.reject{|k,v| !v[:target].nil?}
        tokens = tokens.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        tokens.merge(tokens){|k,v| v[:description]}
      end

      def get_aliases(kind=nil)
        aliases = @tokens.reject{|k,v| v[:target].nil?}
        aliases = aliases.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        aliases.merge(aliases){|k,v| v[:target]}
      end

      def get_raw_tokens(kind=nil)
        get_true_tokens(kind).merge(get_aliases(kind))
      end

      def get_tokens(kind=nil)
        tokens = @tokens
        tokens = tokens.reject{|k,v| v[:kind]!=kind} unless kind.nil?
        tokens.merge(tokens){|k,v| v[:description]}
      end
      
      def empty?
        @tokens.empty?
      end

    end # InflectionData

  end
end
