# These are expected to be called by a developer.  They are part of the datatables DSL.
module EffectiveDatatablesControllerHelper

  def render_datatable_index(datatable)
    raise 'expected Effective::Datatable' unless datatable.kind_of?(Effective::Datatable)

    @datatable = datatable
    render file: 'effective/datatables/index'
  end

end
