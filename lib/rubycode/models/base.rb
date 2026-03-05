# frozen_string_literal: true

module RubyCode
  module Models
    # Base class for all models that use the database
    class Base
      class << self
        # Expose Sequel dataset for direct querying
        # Subclasses must implement table_name
        def dataset
          Database.connection[table_name]
        end

        # Delegate common Sequel methods to dataset
        def where(*args)
          dataset.where(*args)
        end

        def order(field, direction = :asc)
          if direction == :desc
            dataset.order(Sequel.desc(field))
          else
            dataset.order(field)
          end
        end

        def latest(field = :id)
          order(field, :desc)
        end

        def oldest(field = :id)
          order(field, :asc)
        end

        def delete
          dataset.delete
        end

        def all
          dataset.all
        end

        def first
          dataset.first
        end

        def last
          dataset.last
        end

        def count
          dataset.count
        end

        # Subclasses must define their table name
        def table_name
          raise NotImplementedError, "Subclasses must define table_name"
        end
      end

      private

      def db
        Database.connection
      end
    end
  end
end
