module Effective
  class DatatablesController < ApplicationController
    skip_log_page_views quiet: true if defined?(EffectiveLogging)

    # This will respond to both a GET and a POST
    def show
      begin
        @datatable = EffectiveDatatables.find(params[:id])
        @datatable.view = view_context

        EffectiveDatatables.authorize!(self, :index, @datatable.collection_class)

        render json: @datatable.to_json
      rescue => e
        EffectiveDatatables.authorized?(self, :index, @datatable.try(:collection_class))
        render json: error_json(e)

        ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
        raise e if Rails.env.development?
      end
    end

    def reorder
      @datatable = EffectiveDatatables.find(params[:id])
      @datatable.view = view_context

      @resource = @datatable.collection.find(params[:reorder][:id])
      EffectiveDatatables.authorize!(self, :update, @resource)

      attribute = @datatable.columns[:_reorder][:reorder]
      new_index = params[:reorder][:new].to_i
      old_index = params[:reorder][:old].to_i

      @resource.class.transaction do
        if new_index > old_index
          @datatable.collection.where("#{attribute} > ? AND #{attribute} <= ?", old_index, new_index).update_all("#{attribute} = #{attribute} - 1")
          @resource.update_column(attribute, new_index)
        end

        if old_index > new_index
          @datatable.collection.where("#{attribute} >= ? AND #{attribute} < ?", new_index, old_index).update_all("#{attribute} = #{attribute} + 1")
          @resource.update_column(attribute, new_index)
        end
      end

      render status: :ok, body: :ok
    end

    private

    def error_json(e)
      {
        data: [],
        draw: params[:draw].to_i,
        effective_datatables_error: (e.message.presence unless e.class.name.include?('ActiveRecord::')) || 'unexpected operation',
        recordsTotal: 0,
        recordsFiltered: 0,
        aggregates: [],
        charts: {}
      }
    end

  end
end
