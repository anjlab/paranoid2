require 'paranoid2/version'

require 'active_support/concern'
require 'active_record'

require 'paranoid2/persistence'
require 'paranoid2/scoping'

module Paranoid2
  extend ActiveSupport::Concern

  def paranoid?
    self.class.paranoid?
  end

  def paranoid_force
    self.class.paranoid_force
  end

  def with_paranoid value, &block
    self.class.with_paranoid value, &block
  end

  module ClassMethods
    def paranoid? ; false ; end

    def paranoid
      include Persistence
      include Scoping
    end

    alias acts_as_paranoid paranoid

    def with_paranoid opts={}
      forced = opts[:force] || paranoid_force
      previous, self.paranoid_force = paranoid_force, forced
      return yield
    ensure
      self.paranoid_force = previous
    end

    def paranoid_force= value
      Thread.current['paranoid_force'] = value
    end

    def paranoid_force
      Thread.current['paranoid_force']
    end

    def has_paranoid model_name, opts={}
      class_name = model_name.to_s.camelize
      klass      = eval class_name

      return if not klass.paranoid?

      field_name = opts[:foreign_key] || "#{model_name}_id"

      send :define_method, model_name do
        field_value = read_attribute field_name
        klass.with_deleted.where(id: field_value).first
      end
    end
  end
end

ActiveRecord::Base.send :include, Paranoid2