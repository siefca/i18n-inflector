# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2011 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains a stub of I18n::Inflector module,
# which extends I18n by adding the ability
# to interpolate patterns containing inflection tokens
# defined in translation data and manipulate on that data.

module I18n

  class <<self
    # This is proxy method that returns an inflector
    # object used by the current I18n backend.
    # 
    # @return [I18n::Inflector::API] inflector the inflector
    #   used by the current backend
    def inflector
      I18n.backend.inflector
    end
  end

  module Inflector

  end # module Inflector

end # module I18n
