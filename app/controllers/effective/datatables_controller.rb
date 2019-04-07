module Effective
  class DatatablesController < ApplicationController
    skip_log_page_views quiet: true if defined?(EffectiveLogging)

    LOCALES_PATH = File.join(Gem::Specification.find_by_name("effective_datatables").gem_dir, 'app', 'assets', 'javascripts', 'dataTables', 'locales')

    AVAILABLE_LOCALES = Hash[
      Dir["#{LOCALES_PATH}/*"].map { |locale| [File.basename(locale), locale] }
    ]

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

        EffectiveDatatables.authorize!(self, :index, @datatable.collection_class)

        @resource = @datatable.collection.find(params[:reorder][:id])

        EffectiveDatatables.authorize!(self, :update, @resource)

        attribute = @datatable.columns[:_reorder][:reorder]
        old_index = params[:reorder][:old].to_i
        new_index = params[:reorder][:new].to_i

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
      rescue Effective::AccessDenied => e
        render(status: :unauthorized, body: 'Access Denied')
      rescue => e
        render(status: :error, body: 'Unexpected Error')
      end

    end

    def i18n
      render :json => JSON.parse(File.read(AVAILABLE_LOCALES[params[:language]] || AVAILABLE_LOCALES['en']))
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
