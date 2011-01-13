# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains a class used to set up some options,
# for engine.

module I18n
  module Inflector

    # This class contains structures for keeping parsed translation data
    # and basic operations for performing on them.
    class InflectionOptions

      attr_accessor :raises
      attr_accessor :aliased_patterns
      attr_accessor :unknown_defaults
      attr_accessor :excluded_defaults

      def initialize
        reset
      end

      def with_ext(option_name, ext=nil)
        ext.nil? ? instance_variable_get("@#{option_name}") : ext!=false
      end

      def reset
        @excluded_defaults  = false
        @unknown_defaults   = true
        @aliased_patterns   = false
        @raises             = false
      end

    end
    
  end
end
