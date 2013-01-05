module Paranoid2
  module Persistence
    extend ActiveSupport::Concern

    def destroy(opts = {})
      with_paranoid(opts) { super() }
    end

    def destroy!(opts = {})
      with_paranoid(opts) { super() }
    end

    def delete(opts = {})
      with_paranoid(opts) do
        update_column(:deleted_at, Time.now) if !deleted? && persisted?
        if paranoid_force
          self.class.unscoped { super() }
        else
          freeze
        end
      end
    end

    def restore(opts={})
      return if !destroyed?

      update_column :deleted_at, nil

      if opts.fetch(:associations) { true }
        restore_associations
      end
    end

    def restore_associations
      self.class.reflect_on_all_associations.each do |a|
        next unless a.klass.paranoid?

        if a.collection?
          send(a.name).restore_all
        else
          a.klass.unscoped { send(a.name).try(:restore) }
        end
      end
    end

    def destroyed?
      !deleted_at.nil?
    end

    def persisted?
      !new_record?
    end

    alias :deleted? :destroyed?

    def destroy_row
      if paranoid_force
        self.deleted_at = Time.now
        super
      else
        delete
        1
      end
    end

    module ClassMethods
      def paranoid? ; true ; end

      def destroy_all!(conditions = nil)
        with_paranoid(force: true) do
          destroy_all(conditions)
        end
      end

      def restore_all
        only_deleted.each &:restore
      end
    end
  end
end