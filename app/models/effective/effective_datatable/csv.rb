module Effective
  module EffectiveDatatable
    module Csv

      def csv_filename
        self.class.name.underscore.parameterize + '.csv'
      end

      def csv_content_type
        'text/csv; charset=utf-8'
      end

      def to_csv_file
        header = columns.map { |_, opts| opts[:label] || '' }

        CSV.generate do |csv|
          csv << header

          collection.find_in_batches do |resources|
            resources = arrayize(resources, csv: true)
            format(resources, csv: true)
            finalize(resources)

            resources.each { |resource| csv << resource }
          end
        end
      end


      # def to_csv_file
      #   header = csv_columns().map { |_, opts| opts[:label] }

      #   CSV.generate do |csv|
      #     csv << header

      #     collection.find_in_batches do |resources|
      #       arrayize(resources, csv_columns).each do |row|
      #         csv << row
      #       end
      #     end
      #   end
      # end

      # def csv_stream
      #   Enumerator.new do |lines|
      #     Tenant.as(:acpo) do
      #       collection.find_each do |resources|
      #         arrayize(resources).each do |resource|
      #           lines << resource
      #         end
      #       end
      #     end
      #   end
      # end

    end
  end
end
