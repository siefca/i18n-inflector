# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2010 by Paweł Wilk
# License::   This program is licensed under the terms of {GNU Lesser General Public License}[link:docs/LGPL-LICENSE.html] or {Ruby License}[link:docs/COPYING.html].
# 
# This file contains I18n::Inflector module,
# which adds wrappers (module functions) for methods
# in I18n::Backend::Inflector module in order to
# access common methods under friendly names.
# 
#--
# 
# Copyright (C) 2010 by Paweł Wilk. All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of either: 1) the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version; or 2) Ruby's License.
# 
# See the file COPYING for complete licensing information.
#
#++
module I18n
  module Inflector

    def raises?(*args);             I18n.backend.inflector_raises?(*args)            end
    def unknown_defaults?(*args);   I18n.backend.inflector_unknown_defaults?(*args)  end
    def excluded_defaults?(*args);  I18n.backend.inflector_excluded_defaults?(*args) end
    def raises(*args);              I18n.backend.inflector_raises(*args)             end
    def unknown_defaults(*args);    I18n.backend.inflector_unknown_defaults(*args)   end
    def excluded_defaults(*args);   I18n.backend.inflector_excluded_defaults(*args)  end
    def reload!;                    I18n.backend.reload!                             end
    def default_token(*args);       I18n.backend.inflection_default_token(*args)     end
    def is_alias?(*args);           I18n.backend.inflection_is_alias?(*args)         end
    def tokens(*args);              I18n.backend.inflection_tokens(*args)            end
    def raw_tokens(*args);          I18n.backend.inflection_raw_tokens(*args)        end
    def true_tokens(*args);         I18n.backend.inflection_true_tokens(*args)       end
    def aliases(*args);             I18n.backend.inflection_aliases(*args)           end
    def kinds(*args);               I18n.backend.available_inflection_kinds(*args)   end
    def locales(*args);             I18n.backend.inflected_locales(*args)            end
    def description(*args);         I18n.backend.inflection_token_description(*args) end

    module_function :raises?
    module_function :unknown_defaults?
    module_function :excluded_defaults?
    module_function :raises
    module_function :unknown_defaults
    module_function :excluded_defaults
    module_function :reload!                  
    module_function :default_token
    module_function :is_alias?
    module_function :tokens
    module_function :raw_tokens
    module_function :true_tokens
    module_function :aliases
    module_function :kinds
    module_function :locales
    module_function :description

  end
end
