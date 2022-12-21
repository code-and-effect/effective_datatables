# frozen_string_literal: true

require 'csv'

module Effective
  module EffectiveDatatable
    module Csv

      def csv_filename
        self.class.name.underscore.parameterize + '.csv'
      end

      def csv_content_type
        'text/csv; charset=utf-8'
      end

      def csv_header
        columns.map { |_, opts| opts[:label] || '' }
      end

      def csv_file
        CSV.generate do |csv|
          csv << csv_header()

          collection.find_in_batches do |resources|
            resources = arrayize(resources, csv: true)
            format(resources, csv: true)
            finalize(resources)

            resources.each { |resource| csv << resource }
          end
        end
      end

      def csv_stream
        EffectiveResources.with_resource_enumerator do |lines|
          lines << CSV.generate_line(csv_header)

          if active_record_collection?
            collection.find_in_batches do |resources|
              resources = arrayize(resources, csv: true)
              format(resources, csv: true)
              finalize(resources)

              resources.each { |resource| lines << CSV.generate_line(resource) }
            end
          else
            resources = collection

            format(resources, csv: true)
            finalize(resources)

            resources.each { |resource| lines << CSV.generate_line(resource) }
          end

        end
      end

    end
  end
end
