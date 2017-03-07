# Effective DataTables

Uniquely powerful server-side searching, sorting and filtering of any ActiveRecord or Array collection as well as post-rendered content displayed as a frontend jQuery Datatable.

Use a simple DSL in just one ruby file to implement all features

Search raw database tables and ruby post-rendered results at the same time

Packages the jQuery DataTables assets for use in a Rails 3.2.x & Rails 4.x application using Twitter Bootstrap 3

Works with postgres, mysql, sqlite3 and arrays.

## Getting Started

```ruby
gem 'effective_datatables'
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
//= require effective_datatables
```

Require the stylesheet on the asset pipeline by adding the following to your application.css:

```ruby
*= require effective_datatables
```

## Usage

We create a model, initialize it within our controller, then render it from a view

### The Model

Start by creating a new datatable.

Below is a very simple example file, which we will expand upon later.

This model exists at `/app/datatables/posts_datatable.rb`:

```ruby
class PostsDatatable < Effective::Datatable
  datatable do
    table_column :id
    table_column :user      # if Post belongs_to :user
    table_column :comments  # if Post has_many :comments
    table_column :title
    table_column :created_at
    actions_column
  end

  def collection
    Post.all
  end

end
```

### The Controller

We're going to display this DataTable on the posts#index action

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new
  end
end
```

### The View

Here we just render the datatable:

```erb
<h1>All Posts</h1>
<%= render_datatable(@datatable) %>
```

## How It Works

When the jQuery DataTable is first initialized on the front-end, it makes an AJAX request back to the server asking for data.

The effective_datatables gem intercepts this request and returns the appropriate results.

Whenever a search, sort, filter or pagination is initiated on the front end, that request is interpretted by the server and the appropriate results returned.

Due to the unique search/filter ability of this gem, a mix of raw database tables and processed results may be worked with at the same time.


### Effective::Datatable Model & DSL

Once your controller and view are set up to render a Datatable, the model is the central point to configure all behaviour.

This single model file contains just 1 required method and responds to only 3 DSL commands.

For example: `/app/datatables/posts_datatable.rb`:

```ruby
class PostsDatatable < Effective::Datatable
  datatable do
    default_order :created_at, :desc
    default_entries 25

    table_column :id, :visible => false

    table_column :created_at, :width => '25%'

    table_column :updated_at, :proc => Proc.new { |post| nicetime(post.updated_at) } # just a standard helper as defined in helpers/application_helper.rb

    table_column :user

    table_column :post_category_id, :filter => {:as => :select, :collection => Proc.new { PostCategory.all } } do |post|
      post.post_category.name.titleize
    end

    array_column :comments do |post|
      content_tag(:ul) do
        post.comments.where(:archived => false).map do |comment|
          content_tag(:li, comment.title)
        end.join('').html_safe
      end
    end

    table_column :title, :label => 'Post Title', :class => 'col-title'
    actions_column
  end

  def collection
    Post.where(:archived => false).includes(:post_category)
  end

end
```

### The collection

A required method `def collection` must be defined to return the base ActiveRecord collection.

It can be as simple or as complex as you'd like:

```ruby
def collection
  Post.all
end
```

or (complex example):

```ruby
def collection
  collection = Effective::Order.unscoped.purchased
    .joins(:user)
    .joins(:order_items)
    .group('users.email')
    .group('orders.id')
    .select('users.email AS email')
    .select('orders.*')
    .select("#{query_total} AS total")
    .select("string_agg(order_items.title, '!!OI!!') AS order_items")

  if attributes[:user_id].present?
    collection.where(:user_id => attributes[:user_id])
  else
    collection
  end
end

def query_total
  "SUM((order_items.price * order_items.quantity) + (CASE order_items.tax_exempt WHEN true THEN 0 ELSE ((order_items.price * order_items.quantity) * order_items.tax_rate) END))"
end
```

### Array Backed collection

Don't want to use ActiveRecord? Not a problem.

Define your collection as an Array of Arrays, declare only array_columns, and everything works as expected.

```ruby
class ArrayBackedDatatable < Effective::Datatable
  datatable do
    array_column :id
    array_column :first_name
    array_column :last_name
    array_column :email
  end

  def collection
    [
      [1, 'June', 'Huang', 'june@einstein.com'],
      [2, 'Leo', 'Stubbs', 'leo@einstein.com'],
      [3, 'Quincy', 'Pompey', 'quincy@einstein.com'],
      [4, 'Annie', 'Wojcik', 'annie@einstein.com'],
    ]
  end

end
```

## table_column

This is the main DSL method that you will interact with.

table_column defines a 1:1 mapping between a SQL database table column and a frontend jQuery Datatables table column.  It creates a column.

table_column performs searching and sorting on the raw database records, before any results are rendered.

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

# If the name of the table column matches a belongs_to in our collection's main class
# This column will be detected as a belongs_to and some predefined filters will be set up
# So declaring the following
table_column :user

# Will have the same behaviour as declaring
datatable do
  if attributes[:user_id].blank?
    table_column :user_id, :filter => {:as => :select, :collection => Proc.new { User.all.map { |user| [user.id, user.to_s] }.sort { |x, y| x[1] <=> y[1] } } } do |post|
      post.user.to_s
    end
  end
end
```

All table_columns are `visible: true`, `sortable: true` by default.

## array_column

`array_column` accepts the same options as `table_column` and behaves identically on the frontend.

The difference occurs with sorting and filtering:

array_columns perform searching and sorting on the computed results after all columns have been rendered.

With a `table_column`, the frontend sends some search terms to the server, the raw database table is searched & sorted using standard ActiveRecord .where() and .order(), the appropriate rows returned, and then each row is rendered as per the rendering options.

With an `array_column`, the front end sends some search terms to the server, all rows are returned and rendered, and then the rendered output is searched & sorted.

This allows the output of an `array_column` to be anything complex that cannot be easily computed from the database.

When searching & sorting with a mix of table_columns and array_columns, all the table_columns are processed first so the most work is put on the database, the least on rails.

If you're overriding the `search_column` or `order_column` behaviour of an `array_column`, keep in mind that all values will be strings.

This has the side effect of ordering an `array_column` of numbers, as if they were strings.  To keep them ordered as numbers, call:

```ruby
array_column :price, type: :number do |product|
  number_to_currency(product.price)
end
```

The above code will output the price as a currency, but still sort the values as numbers rather than as strings.


### General Options

The following options control the general behaviour of the column:

```ruby
:column => 'users.id'     # Set this if you're doing something tricky with the database.  Used internally for .order() and .where() clauses
:type => :string          # Derived from the ActiveRecord attribute default datatype.  Controls searching behaviour.  Valid options include :string, :text, :datetime, :date, :integer, :boolean, :year
```

### Display Options

The following options control the display behaviour of the column:

```ruby
:label => 'Nice Label'    # Override the default column header label
:sortable => true|false   # Allow sorting of this column.  Otherwise the up/down arrows on the frontend will be disabled.
:visible => true|false    # Hide this column at startup.  Column visbility can be changed on the frontend.  By default, hidden column filter terms are ignored.
:width => '100%'|'100px'  # Set the width of this column.  Can be set on one, all or some of the columns.  If using percentages, should never add upto more than 100%
:class => 'col-example'   # Adds an html class to the column's TH and all TD elements.  Add more than one class with 'example col-example something'
:responsivePriority => 0  # Set which columns collapse when the table is shrunk down.  10000 is the default value.
```

### Filtering Options

Setting a filter will create an appropriate text/number/select input in the header row of the column.

The following options control the filtering behaviour of the column:

```ruby
table_column :created_at, :filter => false    # Disable filtering on this column entirely
table_column :created_at, :filter => {...}    # Enable filtering with these options

:filter => {:as => :number}
:filter => {:as => :text}

:filter => {:as => :select, :collection => ['One', 'Two'], :selected => 'Two'}
:filter => {:as => :select, :collection => [*2010..(Time.zone.now.year+6)]}
:filter => {:as => :select, :collection => Proc.new { PostCategory.all } }
:filter => {:as => :select, :collection => Proc.new { User.all.order(:email).map { |obj| [obj.id, obj.email] } } }

:filter => {:as => :grouped_select, :collection => {'Active' => Events.active, 'Past' => Events.past }}
:filter => {:as => :grouped_select, :collection => {'Active' => [['Event A', 1], ['Event B', 2]], 'Past' => [['Event C', 3], ['Event D', 4]]} }
```

Some additional, lesser used options include:

```ruby
:filter => {:fuzzy => true} # Will use an ILIKE/includes rather than = when filtering.  Use this for selects.
:filter => {sql_operation => :having}  # Will use .having() instead of .where() to handle aggregate columns (autodetected)
:filter => {include_blank: false}
:filter => {placeholder: false}
```

### Rendering Options

There are a few different ways to render each column's output.

Any standard view helpers like `link_to` or `simple_format` and any custom helpers available to your views will be available.

All of the following rendering options can be used interchangeably:

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

then in your `/app/views/posts/_actions.html.erb` file:

```erb
<p><%= link_to('View', post_path(post)) %></p>
<p><%= link_to('Edit', edit_post_path(post)) %></p>
```

The local object name will either match the database table singular name `post`, the name of the partial `actions`, or `obj` unless overridden with:

```ruby
table_column :actions, :partial => '/posts/actions', :partial_local => 'the_post'
```

There are also a built in helper, `datatables_admin_path?` to considering if the current screen is in the `/admin` namespace:

```ruby
table_column :created_at do |post|
  if datatables_admin_path?
    link_to admin_posts_path(post)
  else
    link_to posts_path(post)
  end
end
```

The request object is available to the table_column, so you could just as easily call:

```ruby
request.referer.include?('/admin/')
```

### Column Header Rendering Options

You can override the default rendering and define a partial to use for the header `<th>`:

```ruby
table_column :special, :header_partial => '/posts/special_header'
```

The following locals will be available in the header partial:

```ruby
form        # The SimpleForm FormBuilder instance
name        # The name of your column
column      # the table_column options
filterable  # whether the dataTable is filterable
```

## actions_column

Creates a column with links to this resource's `show`, `edit` and `destroy` actions.

Sets `responsivePriority: 0` so the column is last to collapse when the table is shrunk down.

Override the default actions by passing your own partial:

```ruby
actions_column partial: 'admin/posts/actions'
```

or just extend the default by

```ruby
actions_column do |post|
  unless post.approved?
    glyphicon_to('ok', approve_post_path(post), title: 'Approve')
  end
end
```

### Showing action buttons

The show/edit/destroy action buttons can be configured to always show, always hide, or to consider the current_user's permission level.

To always show / hide:

```ruby
actions_column show: false, edit: true, destroy: true, unarchive: true
```

To authorize based on the current_user and the `config.authorization_method`:

```ruby
actions_column show: :authorize
```

The above will call the effective_datatables `config.authorization_method` just once to see if the current_user has permission to show/edit/destroy the collection class.

The action button will be displayed if `EffectiveDatatables.authorized?(controller, :edit, Post)` returns true.

To call authorize on each individual resource:

```ruby
actions_column show: :authorize_each
```

Or via a Proc:

```ruby
actions_column show: Proc.new { |resource| can?(:show, resource.parent) }
```

See the `config/initializers/effective_datatable.rb` file for more information.

## bulk_actions_column

Creates a column of checkboxes to select one, some, or all rows and adds a bulk actions dropdown button.

When one or more checkboxes are checked, the bulk actions dropdown is enabled and any defined `bulk_action`s will be available to click.

Clicking a bulk action makes an AJAX POST request with the parameters `ids: [1, 2, 3]` as per the selected rows.

By default, the method used to determine each row's checkbox value is `to_param`. To call a different method use `bulk_actions_column(resource_method: :slug) do ... end`.

This feature has been built with an ActiveRecord collection in mind. To work with an Array backed collection try `resource_method: :first` or similar.

After the AJAX request is done, the datatable will be redrawn so any changes made to the collection will be displayed immediately.

You can define any number of `bulk_action`s, and separate them with one or more `bulk_action_divider`s.

The `bulk_action` method is just an alias for `link_to`, so all the same options will work.

```ruby
datatable do
  bulk_actions_column do
    bulk_action 'Approve all', bulk_approve_posts_path, data: {confirm: 'Approve all selected posts?'}
    bulk_action_divider
    bulk_action 'Send emails', bulk_email_posts_path, data: {confirm: 'Really send emails?'}
  end

  ...

end
```

You still need to write your own controller action to process the bulk action.  Something like:

```ruby
class PostsController < ApplicationController
  def bulk_approve
    @posts = Post.where(id: params[:ids])

    # You should probably write this inside a transaction.  This is just an example.
    begin
      @posts.each { |post| post.approve! }
      render json: { status: 200, message: "Successfully approved #{@posts.length} posts." }
    rescue => e
      render json: { status: 500, message: 'An error occured while approving a post.' }
    end
  end
end
```

and in your `routes.rb`:

```ruby
resources :posts do
  collection do
    post :bulk_approve
  end
end
```

## scopes

When declaring a scope, a form field will automatically be placed above the datatable that can filter on the collection.

The value of the scope, its default value, will be available for use anywehre in your datatable via the `attributes` hash.

```ruby
scopes do
  scope :start_date, Time.zone.now-3.months, filter: { input_html: { class: 'datepicker' } }
end
```

(scopes is declared outside of the `datatable do ... end` block)

and then in your collection, or any `table_column` block:

```ruby
def collection
  Post.where('updated_at > ?', attributes[:start_date])
end
```

As well, you need to change the controller where you define the datatable to be aware of the scope params.

```ruby
@datatable = PostsDatatable.new(params[:scopes])
```

And to display the scopes anywhere in your view:

```ruby
= render_datatable_scopes(@datatable)
```

So initially, the `:start_date` will have the value of `Time.zone.now-3.months` and when submitted by the form, the value will be set there.

The form value will come back as a string, so you may need to `Time.zone.parse` that value.

Pass `scope :start_date, Time.zone.now-3.months, fallback: true` to fallback to the default value when the form submission is not present.

Any `filter: { ... }` options will be passed straight into simple_form.

### current_scope / model scopes

You can also use scopes as defined on your ActiveRecord model

When a scope is passed like follows, without a default value, it is assumed to be a klass level scope:

```ruby
scopes do
  scope :all
  scope :standard, default: true
  scope :extended
  scope :archived
end

def collection
  collection = Post.all
  collection = collection.send(current_scope) if current_scope
  collection
end
```

The front end will render these klass scopes as a radio buttons / button group.

To determine which scope is selected, you can call `current_scope` or `attributes[:current_scope]` or `attributes[:standard]`

When no scopes are selected, and no defaults are present, the above will return nil.

It's a bit confusing, but you can mix and match these with regular attribute scopes.

## aggregates

Each `aggregate` directive adds an additional row to the table's tfoot.

This feature is intended to display a sum or average of all the table's currently displayed values.

```ruby
aggregate :average do |table_column, values, table_data|
  if table_column[:name] == 'user'
    'Average'
  else
    average = (values.sum { |value| convert_to_column_type(table_column, value) } / [values.length, 1].max)
    content_tag(:span, number_to_percentage(average, precision: 0))
  end
end
```

The above aggregate block will be called for each currently visible column in a datatable.

Here `table_column` is the table_column being rendered, `values` is an array of all the values in this one column. `table_data` is the whole transposed array of data.

The values will be whatever datatype each table_column returns.

It might be the case that the formatted values (strings) are returned, which is why `convert_to_column_type` is used above.

## table_columns

Quickly create multiple table_columns all with default options:

```ruby
table_columns :id, :created_at, :updated_at, :category, :title
```

## default_order

Sort the table by this field and direction on start up

```ruby
default_order :created_at, :asc|:desc
```

## default_entries

The number of entries to show per page

```ruby
default_entries :all
```

Valid options are `10, 25, 50, 100, 250, 1000, :all`

## Additional Functionality

There are a few other ways to customize the behaviour of effective_datatables

### Checking for Empty collection

Check whether the datatable has records by calling `@datatable.empty?` and `@datatable.present?`.

Keep in mind, these methods look at the collection's total records, not the currently displayed/filtered records.

### Hide the buttons

To hide the Bulk Actions, Show / Hide Columns, CSV, Excel, Print, etc buttons:

```ruby
render_datatable(@datatable, buttons: false)
```

### Override javascript options

The javascript options used to initialize a datatable can be overriden as follows:

```ruby
render_datatable(@datatable, {dom: "<'row'<'col-sm-12'tr>>", autoWidth: true})
```

Please see [datatables options](https://datatables.net/reference/option/) for a list of initialization options.


### Customize Filter Behaviour

This gem does its best to provide "just works" filtering of both raw SQL (table_column) and processed results (array_column) out-of-the-box.

It's also very easy to override the filter behaviour on a per-column basis.

Keep in mind, that filter terms applied to hidden columns will still be considered in filter results.

To customize filter behaviour, specify a `def search_column` method in the datatables model file.

If the table column being customized is a table_column:

```ruby
def search_column(collection, table_column, search_term, sql_column)
  if table_column[:name] == 'subscription_types'
    collection.where('subscriptions.stripe_plan_id ILIKE ?', "%#{search_term}%")
  else
    super
  end
end
```

And if the table column being customized is an array_column:

```ruby
def search_column(collection, table_column, search_term, index)
  if table_column[:name] == 'price'
    collection.select! { |row| row[index].include?(search_term) }
  else
    super
  end
end
```

### Customize Order Behaviour

The order behaviour can be overridden on a per-column basis.

To custom order behaviour, specify a `def order_column` method in the datatables model file.

If the table column being customized is a table_column:

```ruby
def order_column(collection, table_column, direction, sql_column)
  if table_column[:name] == 'subscription_types'
    sql_direction = (direction == :desc ? 'DESC' : 'ASC')
    collection.joins(:subscriptions).order("subscriptions.stripe_plan_id #{sql_direction}")
  else
    super
  end
end
```

And if the table column being customized is an array_column:

```ruby
def order_column(collection, table_column, direction, index)
  if table_column[:name] == 'price'
    if direction == :asc
      collection.sort! { |a, b| a[index].gsub(/\D/, '').to_i <=> b[index].gsub(/\D/, '').to_i }
    else
      collection.sort! { |a, b| b[index].gsub(/\D/, '').to_i <=> a[index].gsub(/\D/, '').to_i }
    end
  else
    super
  end
end
```

### Initialize with attributes

Any attributes passed to `.new()` will be persisted through the lifecycle of the datatable.

You can use this to scope the datatable collection or create even more advanced search behaviour.

In the following example we will hide the User column and scope the collection to a specific user.

In your controller:

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new(:user_id => current_user.try(:id))
  end
end
```

And then in your datatable:

```ruby
class PostsDatatable < Effective::Datatable
  datatable do
    if attributes[:user_id].blank?
      table_column :user_id { |post| post.user.email }
    end
  end

  def collection
    if attributes[:user_id]
      Post.where(user_id: attributes[:user_id])
    else
      Post.all
    end
  end
end
```

### Helper methods

Any non-private methods defined in the datatable model will be available to your table_columns and evaluated in the view_context.

```ruby
class PostsDatatable < Effective::Datatable
  def format_post_title(post)
    if post.title.start_with?('important')
      link_to(post.title.upcase, post_path(post))
    else
      link_to(post.title, post_path(post))
    end
  end

  datatable do
    table_column :title do |post|
      format_post_title(post)
    end
  end

  def collection
    Post.all
  end
end
```

You can also get the same functionality by including a regular Rails helper within the datatable model.

```ruby
module PostHelper
end
```

```ruby
class PostsDatatable < Effective::Datatable
  include PostsHelper
end
```

## Working with other effective_gems

### Effective Addresses

When working with an ActiveRecord collection that implements [effective_addresses](https://github.com/code-and-effect/effective_addresses),
the filters and sorting will be automatically configured.

Just define `table_column :addresses`

When filtering values in this column, the address1, address2, city, postal code, state code and country code will all be matched.

### Effective Obfuscation

When working with an ActiveRecord collection that implements [effective_obfuscation](https://github.com/code-and-effect/effective_obfuscation) for the ID column,
that column's filters and sorting will be automatically configured.

Just define `table_column :id`

Unfortunately, due to the effective_obfuscation algorithm, sorting and filtering by partial values is not supported.

So the column may not be sorted, and may only be filtered by typing the entire 10-digit number, with or without any formatting.

### Effective Roles

When working with an ActiveRecord collection that implements [effective_roles](https://github.com/code-and-effect/effective_roles),
the filters and sorting will be automatically configured.

Just define `table_column :roles`

The `EffectiveRoles.roles` collection will be used for the filter collection, and sorting will be done by roles_mask.


## Get access to the raw results

After all the searching, sorting and rendering of final results is complete, the server sends back an Array of Arrays to the front end jQuery DataTable

The finalize method provides a hook to process the final collection as an Array of Arrays just before it is convered to JSON.

This final collection is available after searching, sorting and pagination.

As you have full control over the table_column presentation, I can't think of any reason you would actually need or want this:

```ruby
def finalize(collection)
  collection.each do |row|
    row.each do |column|
      column.gsub!('horse', 'force') if column.kind_of?(String)
    end
  end
end
```

## Customize the datatables JS initializer

You can customize the initializer javascript passed to datatables.

The support for this is still pretty limitted.

```
= render_datatable(@datatable, {colReorder: false})
```

```
= render_datatable(@datatable, { buttons_export_columns: ':visible:not(.col-actions)' })
```

## Authorization

All authorization checks are handled via the config.authorization_method found in the `config/initializers/effective_datatables.rb` file.

It is intended for flow through to CanCan or Pundit, but neither of those gems are required.

This method is called by the controller action with the appropriate action and resource

Action will be `:index`

The resource will be the collection base class, such as `Post`.  This can be overridden:

```ruby
def collection_class
  NotPost
end
```

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
def authorize!(action, resource)
  current_user.is?(:admin) || EffectivePunditPolicy.new(current_user, resource).send('#{action}?')
end

# Or:

def my_authorization_method
  Your logic here
end
```

or disabled entirely:

```ruby
config.authorization_method = false
```

If the method or proc returns false (user is not authorized) an `Effective::AccessDenied` exception will be raised

You can rescue from this exception by adding the following to your application_controller.rb:

```ruby
rescue_from Effective::AccessDenied do |exception|
  respond_to do |format|
    format.html { render 'static_pages/access_denied', :status => 403 }
    format.any { render :text => 'Access Denied', :status => 403 }
  end
end
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)


## Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

