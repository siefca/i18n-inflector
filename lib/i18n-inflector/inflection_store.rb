# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains class that is used to keep
# collections of the inflection data.

# @abstract This namespace is shared with I18n subsystem.
module I18n
  module Inflector

    class InflectionStore < InflectionData

      attr_reader :strict

      def initialize(locale=nil)
        super
        @strict = I18n::Inflector::InflectionData::Strict.new(locale)
      end

    end

  end
end
