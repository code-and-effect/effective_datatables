module Effective
  class DatatablesController < ApplicationController

    def show
      @datatable = Effective::Datatable.find(params[:id])
      @datatable.view = view_context

      EffectiveDatatables.authorized?(self, :read, @datatable)

      respond_to do |format|
        format.html
        format.json { render :json => (@datatable.to_json rescue error_json) }
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
