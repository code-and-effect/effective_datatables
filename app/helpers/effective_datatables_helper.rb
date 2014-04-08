module EffectiveDatatablesHelper
  def render_datatable(datatable)
    render :partial => 'effective/datatables/datatable', :locals => {:datatable => datatable}
  end

  def datatable_filter(datatable)
    datatable.table_columns.values.map { |options, _| options[:filter] || {:type => 'null'} }.to_json()
  end

  def datatable_non_sortable(datatable)
    [].tap do |nonsortable|
      datatable.table_columns.values.each_with_index { |options, x| nonsortable << x if options[:sortable] == false }
    end.to_json()
  end


end
