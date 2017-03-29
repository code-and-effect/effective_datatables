module Effective
  module EffectiveDatatable
    module Dsl
      module Charts
        # Instance Methods inside the charts do .. end block
        def chart(name, as = 'BarChart', label: nil, legend: true, partial: nil, **options, &compute)
          raise 'expected a block returning an Array of Arrays' unless block_given?

          datatable._charts[name.to_sym] = {
            as: as,
            compute: compute,
            name: name,
            options: { label: (label || name.to_s.titleize), legend: (legend || 'none') }.merge(options),
            partial: partial || '/effective/datatables/chart'
          }
        end
      end
    end
  end
end
