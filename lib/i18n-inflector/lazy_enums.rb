# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains lazy enumerators.

module I18n
  module Inflector
    
    # This class adds some methods for enumarating collections
    # in a lazy way.
    class LazyEnums
      
      def initialize(obj)
        @obj = obj
      end

      def l_map(&block)
        Enumerator.new do |yielder|
          @obj.each do |value|
            yielder.yield(block.call(value))
          end
        end
      end

      def lh_reject(&block)
        Enumerator.new do |yielder|
          @obj.reject do |k,v|
            yielder.yield(k,v) unless block.call(k,v)
          end
        end
      end

      def lh_select(&block)
        Enumerator.new do |yielder|
          @obj.reject do |k,v|
            yielder.yield(k,v) if block.call(k,v)
          end
        end
      end

      def to_h(obj)
        Hash[obj.to_a]
      end

      private

      def method_missing(method, *args, &block)
        if @obj.respond_to?(method) && !@obj.protected_methods.include?(method.to_s)
          @obj.public_send(method, *args, &block)
        else
          @obj.send(:method_missing, method, *args, &block)
        end
      end
        
      def respond_to?(method_symbol, include_private=false)
        @obj.respond_to?(method_symbol, include_private)
      end
      
    end

  end
end
