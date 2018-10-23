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
      begin
        @datatable = EffectiveDatatables.find(params[:id])
        @datatable.view = view_context

        EffectiveDatatables.authorize!(self, :update, @datatable.collection_class)

        render status: :ok

      rescue => e
        EffectiveDatatables.authorized?(self, :update, @datatable.try(:collection_class))
        render json: error_json(e)

        ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
        raise e if Rails.env.development?
      end

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
