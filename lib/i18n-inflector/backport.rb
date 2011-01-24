# This file contains backports for Enumerator class. It uses code from
# the backports library created by Marc-Andre Lafortune.
# 
# Copyright (c) 2009 Marc-Andre Lafortune
# Portions copyright (c) 2011 Pawel Wilk
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module I18n
  module Inflector

    # This module contains some backport methods for older
    # versions of Ruby. It's needed for lazy enumerators
    # to work properly.
    module Backport

      def alias_method_chain(mod, target, feature)
        mod.class_eval do
          # Strip out punctuation on predicates or bang methods since
          # e.g. target?_without_feature is not a valid method name.
          aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
          yield(aliased_target, punctuation) if block_given?

          with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}", "#{aliased_target}_without_#{feature}#{punctuation}"

          alias_method without_method, target
          alias_method target, with_method

          case
            when public_method_defined?(without_method)
              public target
            when protected_method_defined?(without_method)
              protected target
            when private_method_defined?(without_method)
              private target
          end
        end # mod.class_eval
      end
      module_function :alias_method_chain

      def alias_method(mod, new_name, old_name)
        mod.class_eval do
          alias_method new_name, old_name if method_defined?(old_name) and not method_defined?(new_name)
        end
      end
      module_function :alias_method

      # A simple class which allows the construction of Enumerator from a block
      class Yielder
        def initialize(&block)
          @main_block = block
        end

        def each(&block)
          @final_block = block
          @main_block.call(self)
        end

        def yield(*arg)
          #@final_block.yield(*arg) – commented out since older ruby18 does not have yield on proc
          @final_block.call(*arg)
        end
      end

    end # module Backport
  end # module Inflector
end # module i18n

if RUBY_VERSION.gsub(/\D/,'').to_i < 190

  require 'enumerator' rescue nil
  Enumerator = Enumerable::Enumerator unless Object.const_defined?(:Enumerator)

  # @private
  class Enumerator
    unless (self.new{} rescue false)
      def initialize_with_block(*args, &block)
        return initialize_without_block(*args, &nil) unless args.empty?
        initialize_with_block(I18n::Inflector::Backport::Yielder.new(&block))
      end
      I18n::Inflector::Backport.alias_method_chain self, :initialize, :block
    end

    I18n::Inflector::Backport.alias_method self, :with_object, :each_with_object
  end

end

