module Effective
  class ActiveRecordDatatableTool
    attr_accessor :table_columns

    delegate :search_column, :order_column, :collection_class, :quote_sql, :page, :per_page, :to => :@datatable

    def initialize(datatable, table_columns)
      @datatable = datatable
      @table_columns = table_columns
    end

    # Not every ActiveRecord query will work when calling the simple .count
    # Custom selects:
    #   User.select(:email, :first_name).count will throw an error
    #   .count(:all) and .size seem to work
    # Grouped Queries:
    #   User.all.group(:email).count will return a Hash
    def size(collection)
      count = (collection.size rescue nil)

      case count
      when Integer
        count
      when Hash
        count.size  # This represents the number of displayed datatable rows, not the sum all groups (which might be more)
      else
        if collection.klass.connection.respond_to?(:unprepared_statement)
          collection_sql = collection.klass.connection.unprepared_statement { collection.to_sql }
          (collection.klass.connection.exec_query("SELECT COUNT(*) FROM (#{collection_sql}) AS datatables_total_count").rows[0][0] rescue 1)
        else
          (collection.klass.connection.exec_query("SELECT COUNT(*) FROM (#{collection.to_sql}) AS datatables_total_count").rows[0][0] rescue 1)
        end.to_i
      end
    end

    def search_terms
      @search_terms ||= @datatable.search_terms.select { |name, search_term| table_columns.key?(name) }
    end

    def order_by_column
      @order_by_column ||= table_columns[@datatable.order_name]
    end

    def order(collection)
      return collection unless order_by_column.present?

      column_order = order_column(collection, order_by_column, @datatable.order_direction, order_by_column[:sql_column])
      raise 'order_column must return an ActiveRecord::Relation object' unless column_order.kind_of?(ActiveRecord::Relation)
      column_order
    end

    def order_column_with_defaults(collection, table_column, direction, sql_column)
      before = ''; after = ''
      sql_direction = (direction == :desc ? 'DESC' : 'ASC')

      if postgres?
        after = if table_column[:nulls] == :first
          ' NULLS FIRST'
        elsif table_column[:nulls] == :last
          ' NULLS LAST'
        else
          " NULLS #{direction == :desc ? 'FIRST' : 'LAST' }"
        end
      elsif mysql?
        before = "ISNULL(#{sql_column}), "
      end

      if table_column[:as] == :belongs_to_polymorphic
        collection.order("#{before}#{sql_column.sub('_id', '_type')} #{sql_direction}, #{sql_column} #{sql_direction}#{after}")
      elsif table_column[:sql_as_column] == true
        collection.order("#{sql_column} #{sql_direction}")
      else
        collection.order("#{before}#{sql_column} #{sql_direction}#{after}")
      end
    end

    def search(collection)
      search_terms.each do |name, search_term|
        column_search = search_column(collection, table_columns[name], search_term, table_columns[name][:sql_column])
        raise 'search_column must return an ActiveRecord::Relation object' unless column_search.kind_of?(ActiveRecord::Relation)
        collection = column_search
      end
      collection
    end

    def search_column_with_defaults(collection, table_column, term, sql_column)
      sql_op = table_column[:search][:sql_operation] || :where # only other option is :having

      case table_column[:as]
      when :string, :text
        if sql_op != :where
          collection.public_send(sql_op, "#{sql_column} = :term", term: term)
        elsif ['null', 'nil', nil].include?(term)
          collection.public_send(sql_op, "#{sql_column} = :term OR #{sql_column} IS NULL", term: '')
        elsif table_column[:search][:fuzzy]
          collection.public_send(sql_op, "#{sql_column} #{ilike} :term", term: "%#{term}%")
        else
          collection.public_send(sql_op, "#{sql_column} = :term", term: term)
        end
      when :belongs_to_polymorphic
        # our key will be something like Post_15, or Event_1
        (type, id) = term.split('_')

        if type.present? && id.present?
          collection.public_send(sql_op, "#{sql_column} = :id AND #{sql_column.sub('_id', '_type')} = :type", id: id, type: type)
        else
          collection
        end
      when :has_many
        reflection = collection.klass.reflect_on_association(table_column[:name].to_sym)
        raise "unable to find #{collection.klass.name} :has_many :#{table_column[:name]} association" unless reflection

        obj = reflection.build_association({})
        klass = obj.class
        polymorphic = reflection.options[:as].present?

        inverse = reflection.inverse_of
        inverse ||= klass.reflect_on_association(reflection.options[:as]) if polymorphic
        inverse ||= klass.reflect_on_association(collection.table_name)
        inverse ||= obj.class.reflect_on_association(collection.table_name.singularize)

        raise "unable to find #{klass.name} has_many :#{collection.table_name} or belongs_to :#{collection.table_name.singularize} associations" unless inverse

        ids = if [:select, :grouped_select].include?(table_column[:search][:as])
          # Treat the search term as one or more IDs
          inverse_ids = term.split(',').map { |term| (term = term.to_i) == 0 ? nil : term }.compact
          return collection unless inverse_ids.present?

          if polymorphic
            klass.where(id: inverse_ids).where(reflection.type => collection.klass.name).pluck(reflection.foreign_key)
          else
            klass.where(id: inverse_ids).joins(inverse.name).pluck(inverse.foreign_key)
          end
        else
          # Treat the search term as a string.
          klass_columns = if (sql_column == klass.table_name) # No custom column has been defined
            klass.columns.map { |col| col.name if col.text? }.compact  # Search all database text? columns
          else
            [sql_column.gsub("#{klass.table_name}.", '')] # table_column :order_items, column: 'order_items.title'
          end

          if polymorphic
            klass_columns -= [reflection.type]
          end

          conditions = klass_columns.map { |col_name| "#{klass.table_name}.#{col_name} #{ilike} :term" }

          if polymorphic
            klass.where(conditions.join(' OR '), term: "%#{term}%", num: term.to_i).where(reflection.type => collection.klass.name).pluck(reflection.foreign_key)
          else
            klass.where(conditions.join(' OR '), term: "%#{term}%", num: term.to_i).joins(inverse.name).pluck(inverse.foreign_key)
          end
        end

        collection.public_send(sql_op, id: ids)

      when :has_and_belongs_to_many
        reflection = collection.klass.reflect_on_association(table_column[:name].to_sym)
        raise "unable to find #{collection.klass.name} :has_and_belongs_to_many :#{table_column[:name]} association" unless reflection

        obj = reflection.build_association({})
        klass = obj.class

        inverse = reflection.inverse_of || klass.reflect_on_association(collection.table_name) || obj.class.reflect_on_association(collection.table_name.singularize)
        raise "unable to find #{klass.name} has_and_belongs_to_many :#{collection.table_name} or belongs_to :#{collection.table_name.singularize} associations" unless inverse

        ids = if [:select, :grouped_select].include?(table_column[:search][:as])
          # Treat the search term as one or more IDs
          inverse_ids = term.split(',').map { |term| (term = term.to_i) == 0 ? nil : term }.compact
          return collection unless inverse_ids.present?

          klass.where(id: inverse_ids).flat_map { |klass| (klass.send(inverse.name).pluck(:id) rescue []) }
        else
          # Treat the search term as a string.

          klass_columns = if (sql_column == klass.table_name) # No custom column has been defined
            klass.columns.map { |col| col.name if col.text? }.compact  # Search all database text? columns
          else
            [sql_column.gsub("#{klass.table_name}.", '')] # table_column :order_items, column: 'order_items.title'
          end

          conditions = klass_columns.map { |col_name| "#{klass.table_name}.#{col_name} #{ilike} :term" }

          klass.where(conditions.join(' OR '), term: "%#{term}%", num: term.to_i).flat_map { |klass| (klass.send(inverse.name).pluck(:id) rescue []) }
        end

        collection.public_send(sql_op, id: ids)
      when :obfuscated_id
        if (deobfuscated_id = collection.deobfuscate(term)) == term # We weren't able to deobfuscate it, so this is an Invalid ID
          collection.public_send(sql_op, "#{sql_column} = :term", term: 0)
        else
          collection.public_send(sql_op, "#{sql_column} = :term", term: deobfuscated_id)
        end
      when :effective_address
        ids = Effective::Address
          .where('addressable_type = ?', collection_class.name)
          .where("address1 #{ilike} :term OR address2 #{ilike} :term OR city #{ilike} :term OR postal_code #{ilike} :term OR state_code = :code OR country_code = :code", term: "%#{term}%", code: term)
          .pluck(:addressable_id)

        collection.public_send(sql_op, id: ids)
      when :effective_roles
        collection.with_role(term)
      when :datetime, :date
        begin
          digits = term.scan(/(\d+)/).flatten.map { |digit| digit.to_i }
          start_at = Time.zone.local(*digits)

          case digits.length
          when 1  # Year
            end_at = start_at.end_of_year
          when 2 # Year-Month
            end_at = start_at.end_of_month
          when 3 # Year-Month-Day
            end_at = start_at.end_of_day
          when 4 # Year-Month-Day Hour
            end_at = start_at.end_of_hour
          when 5 # Year-Month-Day Hour-Minute
            end_at = start_at.end_of_minute
          when 6
            end_at = start_at + 1.second
          else
            end_at = start_at
          end

          collection.public_send(sql_op, "#{sql_column} >= :start_at AND #{sql_column} <= :end_at", start_at: start_at, end_at: end_at)
        rescue => e
          collection
        end
      when :boolean
        collection.public_send(sql_op, "#{sql_column} = :term", term: [1, 'true', 'yes'].include?(term.to_s.downcase))
      when :integer
        collection.public_send(sql_op, "#{sql_column} = :term", term: term.gsub(/\D/, '').to_i)
      when :year
        collection.public_send(sql_op, "EXTRACT(YEAR FROM #{sql_column}) = :term", term: term.to_i)
      when :price
        price_in_cents = (term.gsub(/[^0-9|\.]/, '').to_f * 100.0).to_i
        collection.public_send(sql_op, "#{sql_column} = :term", term: price_in_cents)
      when :currency, :decimal, :number, :percentage
        collection.public_send(sql_op, "#{sql_column} = :term", term: term.gsub(/[^0-9|\.]/, '').to_f)
      else
        collection.public_send(sql_op, "#{sql_column} = :term", term: term)
      end
    end

    def paginate(collection)
      collection.page(page).per(per_page)
    end

    protected

    def postgres?
      return @postgres unless @postgres.nil?
      @postgres ||= (collection_class.connection.kind_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) rescue false)
    end

    def mysql?
      return @mysql unless @mysql.nil?
      @mysql ||= (collection_class.connection.kind_of?(ActiveRecord::ConnectionAdapters::Mysql2Adapter) rescue false)
    end

    def ilike
      @ilike ||= (postgres? ? 'ILIKE' : 'LIKE')  # Only Postgres supports ILIKE, Mysql and Sqlite3 use LIKE
    end

  end
end
