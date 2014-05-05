# Effective Data Tables

Rails 3.2.x and Rails 4

WIP

to install

gemfile include
and 
gem 'jquery-datatables-rails', github: 'rweng/jquery-datatables-rails'
gem 'kaminari'

javascripts include
stylesheets include

Just create a file in /app/models/effective/datatables/news.rb

```ruby
module Effective
  module Datatables
    class News < Effective::Datatable

      table_column :id

      table_column :created_at do |news| 
        nicetime(news.created_at) 
      end

      table_column :updated_at, :proc => Proc.new { |news| nicetime(news.updated_at) }

      table_column :category, :filter => {:type => :select, :values => ::News::CATEGORIES }
      table_column :title
      table_column :actions, :sortable => false, :filter => false, :partial => '/admin/news/actions'

      def collection
        ::News.all
      end

    end
  end
end
```

