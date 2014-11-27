module Effective
  class DatatablesController < ApplicationController
    skip_log_page_views if defined?(EffectiveLogging)

    def show
      @datatable = Effective::Datatable.find(params[:id], params[:attributes])
      @datatable.view = view_context if @datatable.present?

      EffectiveDatatables.authorized?(self, :index, @datatable.collection_class)

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

    def error_json
      {
        :sEcho => params[:sEcho].to_i,
        :aaData => [],
        :iTotalRecords => 0,
        :iTotalDisplayRecords => 0,
      }.to_json
    end

  end
end
