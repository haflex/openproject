# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class RailsComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :options

  def initialize(**options)
    super
    @options = options
  end

  ##
  # Defines options for this cell which can be used within the cell's template.
  # Options are passed to the cell during the render call.
  #
  # @param names [Array<String> | Hash<String, Any>] Either a list of names for options whose
  #                                                  default value is empty or a hash mapping
  #                                                  option names to default values.
  def self.options(*names)
    default_values = {}

    if names.size == 1 && names.first.is_a?(Hash)
      default_values = names.first
      names = default_values.keys
    end

    names.each do |name|
      define_method(name) do
        options[name] || default_values[name]
      end
    end
  end
end
