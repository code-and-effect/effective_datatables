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
      default_order :created_at, :desc

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

Options for table_column

```ruby
table_column :id   # The name of the table column as per the database (or a .select('something' AS 'blah'))
table_column :name => :id  # The same thing as above
```

Additional options:

```ruby
:label => 'Nice Label' # override the default column header label
:column => 'users.id'  # derived from name by default, used for .order() and .where() clauses
:type => :string       # derived from db table by default, used for searching.  Valid options include :string, :text, :datetime, :integer, :year, :boolean
:sortable => true|false  # allow sorting on this column. default true
:visible => true|false # hide this column at startup
:width => '100%'|'100px'  # set the width of this column.  Can be set on one, all or some of the columns.  Should never add up to more than 100%
```

Rendering options:

There are a few different ways to render each column cell.
This will be called once for each row

```ruby
table_column :created_at do |user|
  my_fancy_format_helper(user.created_at) # or whatever
end

table_column :created_at, :proc => Proc.new { |user| my_fancy_format_helper(user.created_at) }

table_column :created_at, :partial => '/admin/users/actions'  # render this partial for each row of the table
table_column :created_at, :partial_local => 'obj' # The name of the local object in the partial.  Defaults to 'user' or 'actions' or 'obj'
```

Filtering options:

```ruby
table_column :created_at, :filter => false  # Disable filtering on this column entirely
table_column :created_at, :filter => {...}

:filter => {:type => :number|:text}
:filter => {:type => :select, :values => ['One', 'Two'], :selected => 'Two'}

:filter => {:when_hidden => true}  # By default a hidden column's search filter will be ignored, unless this is true
:filter => {:fuzzy => true} # will use an ILIKE/includes rather than = (for selects basically)

```
