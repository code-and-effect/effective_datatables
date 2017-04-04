# Effective DataTables

Use a high level DSL and just one ruby file to create a [jQuery datatable](http://datatables.net/) for any ActiveRecord class or Array.

Powerful server-side searching, sorting and filtering of ActiveRecord classes, with `belongs_to` and `has_many` relationships.

Does the right thing with searching sql columns as well as computed values from both ActiveRecord and Array collections.

Displays links to associated edit/show/destroy actions based on `current_user` authorized actions.

Other features include aggregate (total/average) footer rows, bulk actions, show/hide columns, responsive collapsing columns and Google charts.

This gem includes the jQuery DataTables assets.

For use with any Rails 3, 4, 5 application already using Twitter Bootstrap 3.

Works with postgres, mysql, sqlite3 and arrays.

## effective_datatables 3.0

This is the 3.0 release of effective_datatables.  It's a complete rewrite, with a similar but totally changed DSL.

Previous versions of the gem were excellent, but the 3.0 release has stepped things up.

Internally, all columns now have separate compute and format methods, removing the need for a ton of internal parsing and type conversions.
This allows things like filters, aggregates and searching/sorting to work correctly, always with the before-formatted data.

The mechanism by which columns are rendered has been improved, now all view methods from available from anywhere in the DSL.
This allows you to include/exclude columns based on the current_user, filters and attributes with regular ifs instead of procs.

This release adds a dependency on [effective_resources](https://github.com/code-and-effect/effective_resources) for ActiveRecord resource discovery,
full sql table fuzzy searching/sorting, attribute parsing, and linking to edit/show actions.

A cookie has been added to persist the user's selected filters, search, sort, length, column visibility and pagination settings.

A lot has changed. See below for full details.

# Getting Started

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

# Usage

We create a model, initialize it within our controller, then render it from a view.

## The Model

Start by creating a new datatable.

Below is a minimal example, which we will expand upon later.

This model exists at `/app/datatables/posts_datatable.rb`:

```ruby
class PostsDatatable < Effective::Datatable
  datatable do
    col :created_at
    col :title
    col :user      # Post belongs_to :user
    col :comments  # Post has_many :comments

    actions_col
  end

  collection do
    Post.all
  end
end
```

## The Controller

We're going to display this DataTable on the posts#index action

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new(self)
  end
end
```

## The View

Here we just render the datatable:

```erb
<h1>All Posts</h1>
<%= render_datatable(@datatable) %>
```

# Advanced Usage

Once your controller and view are set up to render a datatable, the model is the central point to configure all behaviour.

Here is an advanced example:

## The Model

This model exists at `/app/datatables/posts_datatable.rb`:

```ruby
class PostsDatatable < Effective::Datatable

  # The collection block is the only required section in a datatable
  # You have access to the attributes and filters Hashes, representing the current state.
  # It must return an ActiveRecord::Relation or an Array of Arrays
  collection do
    scope = Post.includes(:post_category, :user).where(created_at: filters[:start_date]...filters[:end_date])
    scope = scope.where(user_id: attributes[:user_id]) if attributes[:user_id]
    scope
  end

  # Everything in the filters block ends up in a single form.
  # The form is submitted by datatables javascript as an AJAX post
  filters do
    # Scopes are rendered as a single radio button form field. Works well with effective_form_inputs gem.
    # The scopes only work when your collection is an ActiveRecord class. They must exist on the model.
    # The current scope is automatically applied by effective_datatables to your collection.
    # You don't have to consider the current scope when writing your collection block.
    scope :all, default: true
    scope :approved
    scope :draft
    scope :for_user, (attributes[:user_id] ? User.find(attributes[:user_id]) : current_user)

    # Each filter has a name and a default value.  The default can be nil.
    # Each filter is displayed on the front end form as a single field.
    # The filters are NOT automatically applied to your collection.
    # You are responsible for considering filters in your collection block.
    filter :start_date, Time.zone.now-3.months, required: true
    filter :end_date, Time.zone.now.end_of_day
  end

  # These are displayed as a dropdown menu next to the datatables built-in buttons.
  bulk_actions do
    # bulk_action is just passthrough to link_to(), but the action of POST is forced
    # POSTs to the given url with params[:ids], an Array of ids for all selected rows
    # These actions are assumed to change the underlying collection
    bulk_action 'Approve all', bulk_approve_posts_path, data: { confirm: 'Approve all selected posts?' }
    bulk_action_divider
    bulk_action 'Destroy all', bulk_destroy_posts_path, data: { confirm: 'Destroy all selected posts?' }
  end

  # Google Charts
  # https://developers.google.com/chart/interactive/docs/quick_start
  # effective_datatables does all the javascript boilerplate. Just return an Array of Arrays.
  # Charts are updated whenever the current filters and search change
  charts do
    chart :posts_per_day, 'LineChart', label: 'Posts per Day', legend: false do |collection|
      collection.group_by { |post| post.created_at.beginning_of_day }.map do |date, posts|
        [date.strftime('%F'), posts.length]
      end
    end
  end

  # Datatables
  # https://datatables.net/
  # Each column header has a form field controlled by the search: { as: :string } option
  # The user's selected filters, search, sort, length, column visibility and pagination settings are saved between visits
  # on a per-table basis and can be Reset with a button
  datatable do
    length 25  # 5, 10, 25, 50, 100, 1000, :all
    order :updated_at, :desc

    # Renders a column of checkboxes to select items for any bulk_actions
    bulk_actions_col

    col :id, visible: false
    col :updated_at, visible: false

    col :created_at, label: 'Created' do |post|
      time_ago_in_words(post.created_at)
    end

    # This is a belongs_to column
    # effective_datatables will try to put in an edit or show link, depending on the current_user's authorization
    # It will also initialize the search field with PostCategory.all
    col :post_category, action: :edit

    if attributes[:user_id].nil?  # Show all users, otherwise this table is meant for one user only
      col :user, search: { collection: User.authors }
    end

    if can?(:index, Comment)
      col :comments
    end

    col :category, search: { collection: Post::CATEGORY } do |survey|
      Post::CATEGORY.invert[post.category]
    end

    # This is a computed method, not an attribute on the post database table.
    # The first block takes the object from the collection do ... end block and does some work on it.
    # It computes some value. A val.
    # The first block returns a Float/Integer.  All sorting/ordering is then performed on this number.
    # The second block formats the number and returns a String
    val :approval_rating do |post|
      post.approvals.sum { |a| a.rating }
    end.format do |rating|
      number_to_percentage(rating, precision: 2)
    end

    # In a col there is only one block, the format block.
    # A col takes the value as per the collection do ... end block and just formats it
    # All sorting/ordering is performed as per the original value.
    col :approved do |post|
      if post.approved?
        content_tag(:span, 'Approved', 'badge badge-approved')
      else
        content_tag(:span, 'Draft', 'badge badge-draft')
      end
    end

    # Will add a Total row to the table's tfoot
    # :average is also supported, or you can do a custom block
    aggregate :total

    # Uses effective_resources gem to discover the resource path and authorization actions
    # Puts in icons to show/edit/destroy actions, if authorized to those actions.
    # Use the actions_col block to add additional actions
    actions_col show: false do |post|
      unless post.approved? && can?(:approve, Post)
        link_to 'Approve', approve_post_path(post) data: { method: :post, confirm: 'Really approve?'}
      end
    end
  end

end
```

## The Controller

Pass in a hash of attributes when initializing the datatable to configure behaviour.

In the above example, when a `user_id` attribute is present, the table displays information for just that one user.

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new(self, user_id: current_user.id)
  end
end
```

## The View

The datatable, filter form and all all charts are rendered individually.  To render them all:

```
<h1>All Posts</h1>
<%= render_datatable_charts(@datatable) %>
<%= render_datatable_filters(@datatable) %>
<%= render_datatable(@datatable) %>
```

# DSL

The effective_datatables DSL is made up of 5 sections: `collection`, `datatable`, `filters` `bulk_actions`, `charts`

Each section has 3 or 4 different commands.

As well, a datatable can be initialized with `attributes`.

## attributes

When initialized with a Hash, that hash is available throughout the entire datatable as `attributes`.

These attributes are serialized and stored in a cookie. Objects won't work. Keep it simple.

Attributes cannot be changed by search, filter, or state in any way.

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new(self, user_id: current_user.id, admin: true)
  end
end
```

Use attributes to restrict the collection scope, exclude columns or otherwise tweak the table.

An example of using `attributes[:user_id]` to make a user specific posts table is above.

Here we do something similar with `attributes[:admin]`:

```ruby
class PostsDatatable < Effective::Datatable
  collection do
    attributes[:admin] ? Post.all : Post.where(draft: false)
  end

  datatable do
    col :title

    if attributes[:admin]
      col :user
    end

    col :post_category
    col :comments

    actions_col show: true, edit: attributes[:admin]
  end
end
```

## collection

The `collection do ... end` block must return an ActiveRecord relation or an Array of Arrays.

```ruby
collection do
  Post.all
end
```

or

```ruby
collection do
  [
    ['June', 'Huang', 'june@einstein.com'],
    ['Leo', 'Stubbs', 'leo@einstein.com'],
    ['Quincy', 'Pompey', 'quincy@einstein.com'],
    ['Annie', 'Wojcik', 'annie@einstein.com'],
  ]
end
```

or

```ruby
collection do
  time_entries = TimeEntry.where(date: filter[:start_date].beginning_of_year...filter[:end_date].end_of_year)
    .group_by { |time_entry| "#{time_entry.client_id}_#{time_entry.created_at.beginning_of_month.strftime('%b').downcase}" }

  Client.all.map do |client|
    [client] + [:jan, :feb, :mar, :apr, :may, :jun, :jul, :aug, :sep, :oct, :nov, :dec].map do |month|
      entries = time_entries["#{client.id}_#{month}"] || []

      calc = TimeEntryCalculator.new(entries)

      [calc.duration, calc.bill_duration, calc.overtime, calc.revenue, calc.cost, calc.net]
    end
  end
end
```

The collection block is responsible for applying any `attribute` and `filter` logic.

When an ActiveRecord collection, the `current_scope`, will be applied by effective_datatables.

All searching and ordering is also done by effective_datatables.

Your collection method should not contain a `.order()`, or implement search in any way.

(Although you could totally get at that information if you wanted by calling `state`)

## datatable

The `datatable do ... end` block configures a table of data.

Initialize the datatable in your controller or view, `@datatable = PostsDatatable.new(self)`, and render it in your view `<%= render_datatable(@datatable) %>`

### col

This is the main DSL method that you will interact with.

`col` defines a 1:1 mapping between the underlying SQL database table column or Array index to a frontend jQuery Datatables table column. It creates a column.

Each column's search and ordering is performed on its underlying value, as per the collection.

It accepts one optional block used to format the value after any search or ordering is done.

The following options are available:

```ruby
action: :show|:edit|false  # :resource and relation columns only. generate links to this action. edit -> show by default
as: :string|:integer|etc   # Sets the type of column
col_class: 'col-green'     # Sets the html class to use on this column's td and th
label: 'My label'          # The label for this column
partial: 'posts/category'  # Render this column with a partial. The local will be named resource
responsive: 500            # Controls how columns collapse https://datatables.net/reference/option/columns.responsivePriority

# Configure the search behavior
search: false
search: :string
search: { as: :string, fuzzy: true }
search: { as: :select, collection: User.all, multiple: true }

sort: true|false           # Should this column be orderable
sql_column: 'posts.rating' # The sql column to search/order on. Only needed when selecting values not on the underlying table.
visible: true|false        # Show/Hide this column by default
width: 50%|100%|300px      # Sets the width property on this column's td.  Don't actually use this.
```

The `:as` setting determines a column's search, order and format behaviour.

It is auto-detected from an ActiveRecord collection's SQL datatype, and set to `:string` for any Array-based collections.

Valid options for `:as` are as follows:

`:belongs_to`, `:belongs_to_polymorphic`, `:has_and_belongs_to_many`, `:has_many`, `:has_one`, `:resource`

and

`:boolean`, `:currency`, `:datetime`, `:date`, `:decimal`, `:duration`, `:email`, `:float`, `:integer`, `:percentage`, `:price`, `:string`, `:text`

These settings are loosely based on the regular datatypes, with some exceptions:

- `:currency` expects the underlying datatype to be a Float.
- `:duration` expects the underlying datatype to be an Integer representing the number of minutes. 120 == 2 hours
- `:email` expects the underlying datatype to be a String
- `:percentage` expects the underlying datatype to be an Integer or a Float. 75 == 0.75 == 75%
- `:price` expects the underlying datatype to be an Integer representing the number of cents. 5000 == $50.00
- `:resource` can be used for an Array based collection which includes an ActiveRecord object

The column will be formatted as per its `as:` setting, unless a format block is included:

```ruby
col :approved do |post|
  if post.approved?
    content_tag(:span, 'Approved', 'badge badge-approved')
  else
    content_tag(:span, 'Draft', 'badge badge-draft')
  end
end
```

You can also set custom search and sort on a per-column basis. See Advanced Search and Sort below.

### val

Shorthand for value, this command also creates a column on the datatable.

It accepts all the same options as `col` with the additional requirement of a "compute" block.

```ruby
val :approval_rating do |post|
  post.approvals.sum { |a| a.rating }
end.format do |rating|
  number_to_percentage(rating, precision: 2)
end
```

So, `val` yields the object from the collection to the first/compute block, and stores the result.

All searching and ordering for this column will be performed on this computed value. (Note: Yep, this is done as an Array search/order and is much slower than a regular SQL query)

The `.format do ... end` block can be used to apply custom formatting.

### bulk_actions_col

Creates a column of checkboxes for use with the `bulk_actions` section.

Each checkbox will submit a value equal to its row `object.to_param` and can be Select All / Select None'd

Use these checkboxes to select one or more rows for the `bulk_actions do ... end` section (below).

You can only have one `bulk_actions_col` per datatable.

### actions_col

When working with an ActiveRecord based collection, this column will consider the `current_user`'s authorization, and generate
icon links to edit, show and destroy actions for the collection class.

The authorization method should be configured in the `config/initializers/effective_datatables.rb` initializer file.

There are just a few options:

```ruby
show: true|false|:auth
edit: true|false|:auth
destroy: true|false|:auth

visible: true|false
```

When the show, edit and destroy actions are `true`, the permission check will be made just once, on the class.
When set to `:auth`, permission to each individual object will be checked.

Use the block syntax to add additional actions

```ruby
actions_col show: false do |post|
  (post.approved? ? link_to('Approve', approve_post_path(post)) : '') +
  glyphicon_to('print', print_ticket_path(ticket), title: 'Print')
end
```

The `glyphicon_to` helper is part of the [effective_resources](https://github.com/code-and-effect/effective_resources) gem, which is a dependency of this gem.

### length

Sets the default number of rows per page. Valid lengths are `5`, `10`, `25`, `50`, `100`, `250`, `1000`, `:all`

When not specified, effective_datatables uses the default as per the `config/initializers/effective_datatables.rb` or 25.

```ruby
length 100
```

### order

Sets the default order of table rows. The first argument is the column, the second the direction.

The column must exist as a `col` or `val` and the direction is either `:asc` or `:desc`.

When not specified, effective_datatables will sort by the first defined column.

```ruby
order :created_at, :asc|:desc
```

### aggregate

The `aggregate` command inserts a row in the table's `tfoot`.

The only option available is `:label`.

You can only have one aggregate per datatable. (Unfortunately, this is a limit of the jQuery Datatables)

There is built in support for automatic `:total` and `:average` aggregates:

```ruby
aggregate :total|:average
```

or write your own:

```ruby
aggregate :average_as_percentage do |values, column|
  if column[:name] == :first_name
    'Average'
  elsif values.present?
    average = values.map { |value| value.presence || 0 }.sum / [values.length, 1].max
    content_tag(:span, number_to_percentage(average, precision: 1))
  end
end
```

In the above example, `values` is an Array containing all row's values for one column at a time.

## filters

Creates a single form with fields for each `filter` and a single radio input field for all `scopes`.

The form is submitted by an AJAX POST action, or, in some advanced circumstances (see Dynamic Columns below) as a regular POST or even GET.

Initialize the datatable in your controller or view, `@datatable = PostsDatatable.new(self)`, and render its filters anywhere by `<%= render_datatable_filters(@datatable) %>`.

### scope

All defined scopes are rendered as a single radio button form field. Works great with the [effective_form_inputs](https://github.com/code-and-effect/effective_form_inputs) gem.

Only supported for ActiveRecord based collections. They must exist as regular scopes on the model.

The currently selected scope will be automatically applied. You shouldn't consider it in your collection block.

```ruby
filters do
  scope :approved
  scope :for_user, current_user
end
```

Must match the scopes in your `app/models/post.rb`:

```ruby
class Post < ApplicationRecord | ActiveRecord::Base
  scope :approved, -> { where(draft: false) }
  scope :for_user, Proc.new { |user| where(user: user) }
end
```

### filter

Each filter has a name and a default/fallback value. If the form is submitted blank, the default values are used.

This ensures that calling `filters[:name]` always return a value. The default can be nil.

Unlike `scope`s, the filters are NOT automatically applied to your collection. You are responsible for considering `filters` in your collection block.

```ruby
filters do
  filter :start_date, Time.zone.now-3.months, required: true
  filter :end_date, nil, parse: -> { |term| Time.zone.local(term).end_of_day }
  filter :user, current_user, as: :select, collection: User.all
end
```

and apply these to your `collection do ... end` block by calling `filters[:start_date]`:

```ruby
collection do
  scope = Post.includes(:post_category, :user).where('created_at > ?', filters[:start_date])

  if filters[:end_date].present?
    scope = scope.where('created_at < ?', filters[:end_date])
  end

  scope
end
```

The filter command has the following options:

```ruby
as: :select|:date|:boolean      # Passed to SimpleForm
label: 'My label'               # Label for this form field
parse: -> { |term| term.to_i }  # Parse the incoming term (string) into whatever datatype
required: true|false            # Passed to SimpleForm
```

Any other option given will be yielded to SimpleForm as `input_html` options.

## bulk_actions

Creates a single dropdown menu with a link to each action, download or content.

Along with this section, you must put a `bulk_actions_col` somewhere in your `datatable do ... end` section.

### bulk_action

Creates a link that becomes clickable when one or more checkbox/rows are selected as per the `bulk_actions_col` column.

A controller action must be created to accept a POST with an array of selected ids, `params[:ids]`.

This is a pass-through to `link_to` and accepts all the same options, except that the method `POST` is forced.

```ruby
bulk_actions do
  bulk_action 'Approve all', bulk_approve_posts_path, data: { confirm: 'Approve all selected posts?' }
end
```

In your `routes` file:

```ruby
resources :posts do
  collection do
    post :bulk_approve
  end
end
```

In your `PostsController`:

```ruby
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
```

### bulk_action_divider

Inserts a menu divider `<li class='divider' role='separator'></li>`

### bulk_download

So it turns out there are some http issues with using an AJAX action to download a file.

A workaround for these issues is included via the [jQuery File Download Plugin](http://johnculviner.com/jquery-file-download-plugin-for-ajax-like-feature-rich-file-downloads/)

The use case for this feature is to download a csv report generated for the selected rows.

```ruby
bulk_actions do
  bulk_download 'Export Report', bulk_export_report_path
end
```

```ruby
def bulk_export_report
  authorize! :export, Post

  @posts = Post.where(id: params[:ids])

  Post.transaction do
    begin
      cookies[:fileDownload] = true

      send_data(PostsExporter.new(@posts).export,
        type: 'text/csv; charset=utf-8; header=present',
        filename: 'posts-export.csv'
      )

      @posts.update_all(exported_at: Time.zone.now)
      return
    rescue => e
      cookies.delete(:fileDownload)
      raise ActiveRecord::Rollback
    end
  end

  render json: { error: 'An error occurred' }
end
```

### bulk_action_content

Blindly inserts content into the dropdown.

```ruby
bulk_actions do
  bulk_action_content do
    content_tag(:li, 'Something')
  end
end
```

Don't actually use this.

## charts

Create a [Google Chart](https://developers.google.com/chart/interactive/docs/quick_start) based on your searched collection, filters and attributes.

No javascript required. Just use the `chart do ... end` block and return an Array of Arrays.

```ruby
charts do
  chart :breakfast, 'BarChart' do |collection|
    [
      ['Bacon', 10],
      ['Eggs', 20],
      ['Toast', 30]
    ]
  end

  chart :posts_per_day, 'LineChart', label: 'Posts per Day', legend: false do |collection|
    collection.group_by { |post| post.created_at.beginning_of_day }.map do |date, posts|
      [date.strftime('%F'), posts.length]
    end
  end
end
```

And then render each chart in your view:

```
<%= render_datatable_chart(@datatable, :breakfast) %>
<%= render_datatable_chart(@datatable, :posts_per_day) %>
```

or all together

```
<%= render_datatable_charts %>
```

All options passed to `chart` are used to initialize the chart javascript.

By default, the only package that is loaded is `corechart`, see the `config/initializers/effective_datatables.rb` file to add more packages.

## Extras

The following commands don't quite fit into the DSL, but are present nonetheless.

### simple

To render a simple table, without pagination, sorting, filtering, export buttons, per page, and default visibility:

```
<%= render_simple_datatable(@datatable) %>
```

### index

If you just want to render a datatable and nothing else, there is a quick way to skip creating a view:

```ruby
class PostsController < ApplicationController
  def index
    render_datatable_index PostsDatatable.new(self)
  end
end
```

will render `views/effective/datatables/index` with the assigned datatable.

## Advanced Search and Sort

The built-in search and ordering can be overridden on a per-column basis.

The only gotcha here is that you must be aware of the type of collection.

In the case of a `col` and an ActiveRecord-based collection:

```ruby
collection do
  Post.all
end

datatable do
  col :post_category do |post|
    content_tag(:span, post.post_category, "badge-#{post.post_category}")
  end.search do |collection, term, column, sql_column|
    # collection is an ActiveRecord scoped collection
    # term is the incoming PostCategory ID as per the search
    # column is this column's attributes Hash
    # sql_column is the column[:sql_column]
    categories = current_user.post_categories.where(id: term.to_i)

    collection.where(post_category_id: categories)  # Must return an ActiveRecord scope
  end.order do |collection, direction, column, sql_column|
    collection.joins(:post_category).order(:post_category => :title, direction)
  end
end
```

And in the case of a `col` with an Array-based collection, or any `val`:

```ruby
collection do
  Client.all.map do |client|
    [client, client.first_name client.last_name, client.purchased_time()]
  end
end

datatable do
  col :client
  col :first_name
  col :last_name

  col :purchased_time do |duration|
    number_to_duration(duration)
  end.search do |collection, term, column, index|
    # collection is an Array of Arrays
    # term is the incoming value as per the search. "3h30m"
    # column is the column's attributes Hash
    # index is this column's index in the collection
    (hours, minutes) = term.to_s.gsub(/[^0-9|h]/, '').split.map(&:to_i)
    duration = (hours.to_i * 60) + minutes.to_i

    collection.select! { |row| row[index] == duration }  # Must return an Array of Arrays
  end.sort do |collection, term, column, index|
    collection.sort! do |x, y|
      x[index] <=> y[index]
    end
  end
end
```

The search and sort for each column will be merged together to form the final results.

## Dynamic Column Count

There are some extra steps to be taken if you want to change the number of columns based on `filters`.

Unfortunatley, the datatable javascript doesn't support dynamic columns, so submitting filters needs to be done via POST instead of AJAX.

The following example displays a client column, and one column per month for each month in a date range:

```ruby
class TimeEntriesPerClientReport < Effective::Datatable

  filters do
    # This instructs the filters form to use a POST, if available, or GET instead of AJAX
    # It posts to the current controller/action, and there are no needed changes in your controller
    changes_columns_count

    filter :start_date, (Time.zone.now - 6.months).beginning_of_month, required: true, label: 'For the month of: ', as: :effective_date_picker
    filter :end_date, Time.zone.now.end_of_month, required: true, label: 'upto and including the whole month of', as: :effective_date_picker
  end

  datatable do
    length :all

    col :client

    selected_months.each do |month|
      col month.strftime('%b %Y'), as: :duration
    end

    actions_column
  end

  collection do
    time_entries = TimeEntry.where(date: filter[:start_date].beginning_of_month...filter[:end_date].end_of_month)
      .group_by { |time_entry| "#{time_entry.client_id}_#{time_entry.created_at.strftime('%b')}" }

    Client.all.map do |client|
      [client] + selected_months.map do |month|
        entries = time_entries["#{client.id}_#{month.strftime('%b')}"] || []

        entries.map { |entry| entry.duration }.sum
      end
    end
  end

  # Returns an array of 2016-Jan-01, 2016-Feb-01 datetimes
  def selected_months
    @selected_months ||= [].tap do |months|
      each_month_between(filter[:start_date].beginning_of_month, filter[:end_date].end_of_month) { |month| months << month }
    end
  end

  # Call with each_month_between(start_date, end_date) { |date| puts date }
  def each_month_between(start_date, end_date, &block)
    while start_date <= end_date
      block.call(start_date)
      start_date = start_date + 1.month
    end
  end
end
```

# Additional Functionality

There are a few other ways to customize the behaviour of effective_datatables

## Checking for Empty collection

Check whether the datatable has records by calling `@datatable.empty?` and `@datatable.present?`.

## Override javascript options

The javascript options used to initialize a datatable can be overriden as follows:

```ruby
render_datatable(@datatable, {dom: "<'row'<'col-sm-12'tr>>", autoWidth: true})
```

```ruby
render_datatable(@datatable, { buttons_export_columns: ':visible:not(.col-actions)' })
```

Please see [datatables options](https://datatables.net/reference/option/) for a list of initialization options.

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
def my_authorization_method(action, resource)
  current_user.is?(:admin) || EffectivePunditPolicy.new(current_user, resource).send('#{action}?')
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

