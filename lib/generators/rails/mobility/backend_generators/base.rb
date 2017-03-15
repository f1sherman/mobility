# frozen-string-literal: true
require "rails/generators/active_record/migration/migration_generator"

module Mobility
  module BackendGenerators
    class Base < ::Rails::Generators::NamedBase
      argument :attributes, type: :array, default: []
      include ::ActiveRecord::Generators::Migration

      def create_migration_file
        if self.class.migration_exists?(migration_dir, migration_file)
          ::Kernel.warn "Migration already exists: #{migration_file}"
        else
          migration_template "#{template}.rb", "db/migrate/#{migration_file}.rb"
        end
      end

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def backend
        self.class.name.split('::').last.gsub(/Backend$/,'').underscore
      end

      protected

      def attributes_with_index
        attributes.select { |a| !a.reference? && a.has_index? }
      end

      private

      def table_exists?
        connection.table_exists?(table_name)
      end

      delegate :connection, to: ::ActiveRecord::Base

      def truncate_index_name(index_name)
        if index_name.size < connection.index_name_length
          index_name
        else
          "index_#{Digest::SHA1.hexdigest(index_name)}"[0, connection.index_name_length].freeze
        end
      end

      def template
        "#{backend}_translations".freeze
      end

      def migration_dir
        File.expand_path("db/migrate".freeze)
      end

      def migration_file
        "create_#{file_name}_#{attributes.map(&:name).join('_and_')}_translations_for_mobility_#{backend}_backend".freeze
      end
    end
  end
end
