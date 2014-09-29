# Effective DataTables

Use just one file and a simple DSL to implement seamless server-side search sort and filtering of any ActiveRecord or Array collection in a frontend jQuery DataTable

Search database tables and computed results (arrays) at the same time

Packages the jQuery DataTables assets for use in a Rails 3.2.x & Rails 4.x application using Twitter Bootstrap 2 or 3


# Getting Started

```ruby
gem 'effective_datatables', :git => 'https://github.com/code-and-effect/effective_datatables'
```

Run the bundle command to install it:

```console
bundle install
```

Install the configuration file:

```console
rails generate effective_datatables:install
```

The generator will install an initializer which describes all configuration options.


Require the javascript on the asset pipeline by adding the following to your application.js:

```ruby
# For use with Bootstrap3 (not included in this gem):
//= require effective_datatables

# For use with Bootstrap2 (not includled in this gem):
//= require effective_datatables.bootstrap2
```

Require the stylesheet on the asset pipeline by adding the following to your application.css:

```ruby
# For use with Bootstrap3 (not included in this gem):
*= require effective_datatables

# For use with Bootstrap2 (not included in this gem):
*= require effective_datatables.bootstrap2
```

# Create and Display an Effective Datatable

We create a model, initialize it within our controller, then render it from a view

## The Model

Start by creating a model in the /app/models/effective/datatables/ directory.

Any Effective::Datatable models that exist in this directory will be automatically detected and "just work".

Below is a very simple example file, which we will expand upon later.

This model exists at /app/models/effective/datatables/posts.rb

```ruby
module Effective
  module Datatables
    class Posts < Effective::Datatable
      table_column :id
      table_column :title
      table_column :created_at

      def collection
        Post.all
      end

    end
  end
end
```

## The Controller

We're going to display this DataTable on the posts#index action

```ruby
class PostsController < ApplicationController
  def index
    @datatable = Effective::Datatables::Posts.new()
  end
end
```

## The View

Here we just render the datatable:

```erb
<h1>All Posts</h1>

<% if @datatable.collection.length == 0 %>
  <p>There are no posts.</p>
<% else %>
  <%= render_datatable(@datatable) %>
<% end %>
```

# How It Works

When the jQuery DataTable is first initialized on the front-end, it makes an AJAX request back to the server asking for data.

The effective_datatables gem intercepts this result and returns the appropriate results.

Whenever a search, sort, filter or pagination is initiated on the front end, that request is interpretted by the server and the appropriate results returned.

Due to the unique search/filter ability of this gem, a mix of raw database tables and computed results may be worked with at the same time.


# Effective::Datatable Model & DSL

Once your controller and view are set up to render a Datatable, this model is the single file you need to configure all behaviour.

This single model contains just 1 required method and responds to only 4 DSL commands.

Each Effective::Datatable model must be defined in the /app/models/effective/datatables/ directory.

For example: /app/models/effective/datatables/posts.rb

```ruby
module Effective
  module Datatables
    class Posts < Effective::Datatable
      default_order :created_at, :desc

      table_column :id, :visible => false

      table_column :created_at, :width => '25%' do |post|
        post.created_at.strftime("%Y-%m-%d %H:%M:%S")
      end

      table_column :updated_at, :proc => Proc.new { |post| nicetime(post.updated_at) } # just a standard helper as defined in helpers/application_helper.rb

      table_column :post_category_id, :filter => {:type => :select, :values => Proc.new { PostCategory.all } } do |post|
        post.post_category.name.titleize
      end

      array_column :comments do |post|
        content_tag(:ul) do
          post.comments.where(:archived => false).map do |comment|
            content_tag(:li, comment.title)
          end.join('').html_safe
        end
      end

      table_column :title, :label => 'Post Title'
      table_column :actions, :sortable => false, :filter => false, :partial => '/posts/actions'

      def collection
        Post.where(:archived => false).includes(:post_category)
      end

    end
  end
end
```

## The collection

A required method "collection" must be defined that returns the base ActiveRecord collection.

It can be as simple or as complex as you'd like:

```ruby
def collection
  Posts.all
end
```

or (complex example):

```ruby
def collection
  User.unscoped.uniq
    .joins('LEFT JOIN customers ON customers.user_id = users.id')
    .select('users.*')
    .select('customers.stripe_customer_id AS stripe_customer_id')
    .includes(:addresses)
end
```

## table_column

This is the main DSL method that you will need to interact with.

table_column defines a 1:1 mapping between a SQL database table column and a frontend jQuery Datatables table column.  It creates a column.

Options may be passed to specify the display, search, sort and filter behaviour for that column.

When the given name of the table_column matches an ActiveRecord attribute, the options are set intelligently based on the underlying datatype.

```ruby
# The name of the table column as per the Database
# This column is detected as an Integer, therefore it is :type => :integer
# Any SQL used to search this field will take the form of "id = ?"
table_column :id

# As per our 'complex' example above, using the .select('customers.stripe_customer_id AS stripe_customer_id') syntax to create a faux database table
# This column is detected as a String, therefore it is :type => :string
# Any SQL used to search this field will take the form of "customers.stripe_customer_id ILIKE %?%"
table_column :stripe_customer_id, :column => 'customers.stripe_customer_id'

# The name of the table column as per the Database
# This column is detected as a DateTime, therefore it is :type => :datetime
# Any SQL used to search this field will take the form of
# "to_char(#{column} AT TIME ZONE 'GMT', 'YYYY-MM-DD HH24:MI') ILIKE '%?%'"
table_column :created_at
```

All table_columns are :visible => true, :sortable => true by default.

### General Options

The following options control the general behaviour of the column:

```ruby
:column => 'users.id'     # Set this if you're doing something tricky with the database.  Used internally for .order() and .where() clauses
:type => :string          # Derived from the ActiveRecord attribute default datatype.  Controls searching behaviour.  Valid options include :string, :text, :datetime, :integer, :boolean, :year
:if => Proc.new { attributes[:user_id].blank? }  # Excludes this table_column entirely if false. See "Initialize with attributes" section of this README below
```

### Display Options

The following options control the display behaviour of the column:

```ruby
:label => 'Nice Label'    # Override the default column header label
:sortable => true|false   # Allow sorting of this column.  Otherwise the up/down arrows on the frontend will be disabled.
:visible => true|false    # Hide this column at startup.  Column visbility can be changed on the frontend.  By default, hidden columns filter terms are ignored.
:width => '100%'|'100px'  # Set the width of this column.  Can be set on one, all or some of the columns.  If using percentages, should never add upto more than 100%
```

### Filtering Options

Setting a filter will create an appropriate text/number/select input in the header row of the column.

The following options control the filtering behaviour of the column:

```ruby
table_column :created_at, :filter => false    # Disable filtering on this column entirely
table_column :created_at, :filter => {...}    # Enable filtering with these options

:filter => {:type => :number}
:filter => {:type => :text}

:filter => {:type => :select, :values => ['One', 'Two'], :selected => 'Two'}
:filter => {:type => :select, :values => [*2010..(Time.zone.now.year+6)]}
:filter => {:type => :select, :values => Proc.new { PostCategory.all } }
:filter => {:type => :select, :values => Proc.new { User.all.order(:email).map { |obj| [obj.id, obj.email] } } }
```

Some additional, lesser used options include:

```ruby
:filter => {:when_hidden => true}  # By default a hidden column's search filter will be ignored, unless this is true.  Can be used for scoping.
:filter => {:fuzzy => true} # Will use an ILIKE/includes rather than = when filtering.  Use this for selects.
```

### Rendering Options

There are a few different ways to render each column cell.  This will be called once for each row.

Any standard view helpers like link_to() or simple_format() and any custom helpers available to ApplicationController will "just work".

All of the following rendering options can be used interchangeably.

Block format (really, this is your cleanest option):

```ruby
table_column :created_at do |post|
  if post.created_at > (Time.zone.now-1.year)
    link_to('this year', post_path(post))
  else
    link_to(post.created_at.strftime("%Y-%m-%d %H:%M:%S"), post_path(post))
  end
end
```

Proc format:

```ruby
table_column :created_at, :proc => Proc.new { |post| link_to(post.created_at, post_path(post)) }
```

Partial format:

```ruby
table_column :actions, :partial => '/posts/actions'  # render this partial for each row of the table
```

then in your /app/views/posts/_actions.html.erb file:

```erb
<p><%= link_to('View', post_path(post)) %></p>
<p><%= link_to('Edit', edit_post_path(post)) %></p>
```

The local object name will either match the database table singular name 'post', the name of the partial 'actions', or 'obj' unless overridden with:

```ruby
table_column :actions, :partial => '/posts/actions', :partial_local => 'the_post'
```

## table_columns

Quickly create multiple table_columns all with default options:

```ruby
table_columns :id, :created_at, :updated_at, :category, :title
```

## array_column

array_column accepts the same options as table_column and behaves the exact same on the frontend.

The difference occurs when sorting and filtering:

With a table_column, the frontend sends some search terms to the server, the raw database table is searched & sorted, the appropriate rows returned, and then each row is rendered as per the rendering options.

With an array_column, the front end sends some search terms to the server, all rows are returned and rendered, and then the rendered output is searched & sorted.

This allows the output of an array_column to be anything complex that cannot be easily computed from the database.

When searching & sorting with a mix of table_columns and array_columns, all the table_columns are processed first so the most work is put on the database, the least on rails.


## default_order

Sort the table by this field and direction on start up

```ruby
default_order :created_at, :asc|:desc
```

# Additional Functionality

There are a few other things effective_datatables can do

## Customize Search Behaviour

This gem does its best to provide "just works" searching both raw SQL (table_column) and final Results (array_column) out-of-the-box.

It's also very easy to customize the search behaviour on a per-column basis.

Keep in mind, columns that are hidden will not have search_terms present unless :filter => {:when_hidden => true} is passed to table_column

For custom search behaviour, overload the search_column method of the datatables model file:

```ruby
def search_column(collection, table_column, search_term)
  if table_column[:name] == 'subscription_types'
    collection.where('subscriptions.stripe_plan_id ILIKE ?', "%#{search_term}%")
  else
    super
  end
end
```

## Initialize with attributes

Additional attributes may be passed to .new() that will be persisted through the lifecycle of the datatable.

You can use this to easily scope the datatable collection or create even more advanced search behaviour.

Let's hide the Users column and scope the Post collection to a user, when the Posts table is initialized with a specific user.

In your controller:

```ruby
class PostsController < ApplicationController
  def index
    @datatable = Effective::Datatables::Posts.new(:user_id => current_user.try(:id))
  end
end
```

And in your collection method:

```ruby
def collection
  if attributes[:user_id].present?
    Post.where(:user_id => attributes[:user_id])
  else
    Post.all
  end
end
```

and/or your table_column definition:

```ruby
table_column :user, :if => Proc.new { attributes[:user_id].blank? }
```

## Get access to the raw results

After all the searching, sorting and rendering of final results is complete, the server sends back an Array of Arrays to the front end jQuery DataTable

The finalize method provides a hook to process the final collection as an Array of Arrays just before it is convered to JSON.

This final collection is available after searching, sorting and pagination.

I can't think of any reason you would actually need or want this:

```ruby
def finalize(collection)
  collection.each do |row|
    row.each do |col|
      col.gsub!('horse', 'force') if col.kind_of?(String)
    end
  end
end
```

# Authorization

All authorization checks are handled via the config.authorization_method found in the config/initializers/ file.

It is intended for flow through to CanCan or Pundit, but that is not required.

This method is called by all controller actions with the appropriate action and resource

Action will be one of [:index, :show, :new, :create, :edit, :update, :destroy]

Resource will the appropriate Effective::Something ActiveRecord object or class

The authorization method is defined in the initializer file:

```ruby
# As a Proc (with CanCan)
config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) }
```

```ruby
# As a Custom Method
config.authorization_method = :my_authorization_method
```

and then in your application_controller.rb:

```ruby
def my_authorization_method(action, resource)
  current_user.is?(:admin) || EffectivePunditPolicy.new(current_user, resource).send('#{action}?')
end
```

or disabled entirely:

```ruby
config.authorization_method = false
```

If the method or proc returns false (user is not authorized) an Effective::AccessDenied exception will be raised

You can rescue from this exception by adding the following to your application_controller.rb:

```ruby
rescue_from Effective::AccessDenied do |exception|
  respond_to do |format|
    format.html { render 'static_pages/access_denied', :status => 403 }
    format.any { render :text => 'Access Denied', :status => 403 }
  end
end
```


# License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect


# Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```
