# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains lazy enumerators.

# @private
#class Enumerator
#  # @private
#  def to_hash
#    Hash[self.to_a]
#  end unless method_defined? :to_h
#end

module I18n
  module Inflector

    class LazyEnumerator < Enumerator

      def to_h
        Hash[self.to_a]
      end

      def a_map(&block)
        LazyEnumerator.new do |yielder|
          self.each do |value|
            yielder.yield(block.call(value))
          end
        end
      end

      def h_map(&block)
        LazyEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,block.call(k,v))
          end
        end
      end

      def h_select(&block)
        LazyEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,v) if block.call(k,v)
          end
        end
      end
    
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
