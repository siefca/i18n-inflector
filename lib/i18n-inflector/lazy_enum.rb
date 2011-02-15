# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:docs/LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains lazy enumerators.

module I18n
  module Inflector

    if RUBY_VERSION.gsub(/\D/,'')[0..1].to_i < 19
      require 'enumerator' rescue nil

      class LazyEnumerator < Object.const_defined?(:Enumerator) ? Enumerator : Enumerable::Enumerator

        # This class allows to initialize the Enumerator with a block
        class Yielder
          def initialize(&block)
            @main_block = block
          end

          def each(&block)
            @final_block = block
            @main_block.call(self)
          end

          if Proc.method_defined?(:yield)
            def yield(*arg)
              @final_block.yield(*arg)
            end
          else
            def yield(*arg)
              @final_block.call(*arg)
            end
          end
        end

        unless (self.new{} rescue false)
          def initialize(*args, &block)
            args.empty? ? super(Yielder.new(&block)) : super(*args, &nil) 
          end
        end

        if method_defined?(:with_object) and not method_defined?(:each_with_object)
          alias_method :with_object, :each_with_object
        end

      end # class LazyEnumerator for ruby18

    else # if RUBY_VERSION >= 1.9.0

      class LazyEnumerator < Enumerator
      end

    end

    # This class implements simple enumerators for arrays
    # that allow to do lazy operations on them.
    class LazyArrayEnumerator < LazyEnumerator

      # Mapping enumerator
      # @return [I18n::Inflector::LazyEnumerator] the enumerator
      def map(&block)
        LazyArrayEnumerator.new do |yielder|
          self.each do |v|
            yielder.yield(block.call(v))
          end
        end
      end

      # Array selecting enumerator
      # @return [I18n::Inflector::LazyHashEnumerator] the enumerator
      def select(&block)
        LazyArrayEnumerator.new do |yielder|
          self.each do |v|
            yielder.yield(v) if block.call(v)
          end
        end
      end

      # Array rejecting enumerator
      # @return [I18n::Inflector::LazyHashEnumerator] the enumerator
      def reject(&block)
        LazyArrayEnumerator.new do |yielder|
          self.each do |v|
            yielder.yield(v) unless block.call(v)
          end
        end
      end

    end

    # This class implements simple enumerators for hashes
    # that allow to do lazy operations on them.
    class LazyHashEnumerator < LazyEnumerator

      # Creates a Hash kind of object by collecting all
      # data from enumerated collection.
      # @return [Hash] the resulting hash
      def to_h
        h = Hash.new
        self.each{|k,v| h[k]=v }
        h
      end

      # Hash mapping enumerator
      # @return [I18n::Inflector::LazyHashEnumerator] the enumerator
      def map(&block)
        LazyHashEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,block.call(k,v))
          end
        end
      end

      # Hash to Array mapping enumerator
      # @return [I18n::Inflector::LazyEnumerator] the enumerator
      def ary_map(&block)
        LazyHashEnumerator.new do |yielder|
          self.each do |value|
            yielder.yield(block.call(value))
          end
        end
      end

      # This method converts resulting keys
      # to an array.
      def keys
        ary = []
        self.each{ |k,v| ary << k }
        return ary
      end

      # This method converts resulting values
      # to an array.
      def values
        ary = []
        self.each{ |k,v| ary << v }
        return ary
      end

      # Hash selecting enumerator
      # @return [I18n::Inflector::LazyHashEnumerator] the enumerator
      def select(&block)
        LazyHashEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,v) if block.call(k,v)
          end
        end
      end

      # Hash rejecting enumerator
      # @return [I18n::Inflector::LazyHashEnumerator] the enumerator
      def reject(&block)
        LazyHashEnumerator.new do |yielder|
          self.each do |k,v|
            yielder.yield(k,v) unless block.call(k,v)
          end
        end
      end

    end # class LazyHashEnumerator

  end
end
