module EffectiveDatatablesHelper
  def render_datatable(datatable)
    render :partial => 'effective/datatables/datatable', :locals => {:datatable => datatable}
  end
end
