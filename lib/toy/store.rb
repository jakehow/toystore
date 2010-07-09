# encoding: UTF-8
module Toy
  module Store
    extend ActiveSupport::Concern

    included do
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include Attributes
      include Persistence
      include Validations
    end

    def persisted?
      false
    end
  end
end