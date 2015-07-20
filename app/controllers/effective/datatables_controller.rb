module Effective
  class DatatablesController < ApplicationController
    skip_log_page_views if defined?(EffectiveLogging)

    # This will respond to both a GET and a POST
    def show
      @datatable = find_datatable(params[:id]).try(:new, params[:attributes])
      @datatable.view = view_context if !@datatable.nil?

      EffectiveDatatables.authorized?(self, :index, @datatable.try(:collection_class) || Effective::Datatable)

      respond_to do |format|
        format.html
        format.json {
          if Rails.env.production?
            render :json => (@datatable.to_json rescue error_json)
          else
            render :json => @datatable.to_json
          end
        }
      end

    end

    private

    def find_datatable(id)
      "effective/datatables/#{id}".classify.tap { |klass| klass << 's' if id.to_s.end_with?('s') }.safe_constantize
    end

    def error_json
      {
        :draw => params[:draw].to_i,
        :data => [],
        :recordsTotal => 0,
        :recordsFiltered => 0,
      }.to_json
    end

  end
end
