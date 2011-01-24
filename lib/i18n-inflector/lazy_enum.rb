# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains lazy enumerators.

module I18n
  module Inflector

    # This class implements simple enumerators for arrays
    # and hashes that allow to do lazy operations on them.
    class LazyEnumerator < Enumerator

      # Creates a Hash kind of object by collecting all
      # data from enumerated collection.
      # @return [Hash] the resulting hash
      def to_h
        Hash[self.to_a]
      end

      # Array mapping enumerator
      # @return [I18n::Inflector::LazyEnumerator] the enumerator
      def a_map(&block)
        LazyEnumerator.new do |yielder|
          self.each do |value|
            yielder.yield(block.call(value))
          end
        end
      end

      # Hash mapping enumerator
      # @return [I18n::Inflector::LazyEnumerator] the enumerator
      def h_map(&block)
        LazyEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,block.call(k,v))
          end
        end
      end

      # Hash selecting enumerator
      # @return [I18n::Inflector::LazyEnumerator] the enumerator
      def h_select(&block)
        LazyEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,v) if block.call(k,v)
          end
        end
      end

      # Hash rejecting enumerator
      # @return [I18n::Inflector::LazyEnumerator] the enumerator
      def h_reject(&block)
        LazyEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,v) unless block.call(k,v)
          end
        end
      end

    end

  end
end
