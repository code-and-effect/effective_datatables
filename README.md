# Effective DataTables

Use a high level DSL and just one ruby file to create a [Datatables jQuery table](http://datatables.net/) for any ActiveRecord class or Array.

Powerful server-side searching, sorting and filtering of ActiveRecord classes, with `belongs_to` and `has_many` relationships.

Does the right thing with searching sql columns as well as computed values from both ActiveRecord and Array collections.

Displays links to associated edit/show/destroy actions based on `current_user` authorized actions.

Other features include aggregate (total/average) footer rows, bulk actions, show/hide columns, responsive collapsing columns, google charts, and inline crud.

This gem includes the jQuery DataTables assets.


Works with postgres, mysql, sqlite3 and arrays.

## Live Demo

Click here for a [Live Demo](https://effective-datatables-demo.herokuapp.com/).

See [effective_datatables_demo](https://github.com/code-and-effect/effective_datatables_demo) for a working rails website example.

## effective_datatables 4.0

This is the 4.0 series of effective_datatables.

This requires Twitter Bootstrap 4 and Rails 5.1+

Please check out [Effective Datatables 3.x](https://github.com/code-and-effect/effective_datatables/tree/bootstrap3) for more information using this gem with Bootstrap 3.

# Contents

* [Getting Started](#getting-started)
* [Quick Start](#quick-start)
* [Usage](#usage)
* [DSL](#dsl)
  * [attributes](#attributes)
  * [collection](#collection)
  * [datatable](#datatable)
    * [col](#col)
    * [val](#val)
    * [bulk_actions_col](#bulk_actions_col)
    * [actions_col](#actions_col)
    * [length](#length)
    * [order](#order)
    * [reorder](#reorder)
    * [aggregate](#aggregate)
  * [filters](#filters)
    * [scope](#scope)
    * [filter](#filter)
  * [bulk_actions](#bulk_actions)
    * [bulk_action](#bulk_action)
    * [bulk_action](#bulk_action_divider)
    * [bulk_download](#bulk_download)
    * [bulk_action_content](#bulk_action_content)
  * [Charts](#charts)
  * [Inline](#inline)
  * [Extras](#extras)
  * [Advanced Search and Sort](#advanced-search-and-sort)
* [Addtional Functionality](#additional-functionality)
  * [Checking for Empty collection](#checking-for-empty-collection)
  * [Override javascript options](#override-javascript-options)
  * [Get access to the raw results](#get-access-to-the-raw-results)
  * [Authorization](#authorization)
* [License](#license)
* [Contributing](#contributing)

# Getting Started

```ruby
gem 'haml-rails'            # or try using gem 'hamlit-rails'
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

Make sure you have [Twitter Bootstrap 4](https://github.com/twbs/bootstrap-rubygem) installed.

Require the javascript on the asset pipeline by adding the following to your application.js:

```ruby
//= require effective_datatables
```

Require the stylesheet on the asset pipeline by adding the following to your application.css:

```ruby
*= require effective_datatables
```

# Quick Start

All logic for the table exists in its own model file.  Once that's built, we initialize in the controller, render in the view.

## The Model

Start by creating a new datatable.

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

We're going to display this DataTable on the posts#index action.

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new
  end
end
```

## The View

Here we just render the datatable:

```erb
<h1>All Posts</h1>
<%= render_datatable(@datatable) %>
```

# Usage

Once your controller and view are set up to render a datatable, the model is the central point to configure all behaviour.

Here is an advanced example:

## The Model

This model exists at `/app/datatables/posts_datatable.rb`:

```ruby
class PostsDatatable < Effective::Datatable

  # The collection block is the only required section in a datatable
  # It has access to the attributes and filters Hashes, representing the current state
  # It must return an ActiveRecord::Relation or an Array of Arrays
  collection do
    scope = Post.all.joins(:user).where(created_at: filters[:start_date]...filters[:end_date])
    scope = scope.where(user_id: attributes[:user_id]) if attributes[:user_id]
    scope
  end

  # Everything in the filters block ends up in a single form
  # The form is submitted by datatables javascript as an AJAX post
  filters do
    # Scopes are rendered as a single radio button form field (works well with effective_bootstrap gem)
    # The scopes only work when your collection is an ActiveRecord class, and they must exist on the model
    # The current scope is automatically applied by effective_datatables to your collection
    # You don't have to consider the current scope when writing your collection block
    scope :all, default: true
    scope :approved
    scope :draft
    scope :for_user, (attributes[:user_id] ? User.find(attributes[:user_id]) : current_user)

    # Each filter has a name and a default value and the default can be nil
    # Each filter is displayed on the front end form as a single field
    # The filters are NOT automatically applied to your collection
    # You are responsible for considering filters in your collection block
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
    length 25  # 5, 10, 25, 50, 100, 500, :all
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
      col :user, search: User.authors.all
    end

    col 'user.first_name'  # Using the joined syntax

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
    # Puts links to show/edit/destroy actions, if authorized to those actions.
    # Use the actions_col block to add additional actions

    actions_col

    # actions_col(edit: false) do |post|
    #   dropdown_link_to('Approve', approve_post_path(post) data: { method: :post, confirm: "Approve #{post}?"})
    # end
  end

end
```

## The Controller

Any options used to initialize a datatable become the `attributes`.  Use these to configure datatables behavior.

In the above example, when `attributes[:user_id]` is present, the table displays information for just that user.

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new(user_id: current_user.id)
  end
end
```

## The View

Render the datatable with its filters and charts, all together:

```
<h1>All Posts</h1>
<%= render_datatable(@datatable) %>
```

or, the datatable, filter and charts may be rendered individually:

```
<h1>All Posts</h1>
<p>
  <%= render_datatable_filters(@datatable) %>
</p>

<p>
  <%= render_datatable_charts(@datatable) %>
</p>

<p>
<%= render_datatable(@datatable, charts: false, filters: false) %>
</p>
```

or, to render a simple table, (without filters, charts, pagination, sorting, searching, export buttons, per page, or default visibility):

```
<%= render_datatable(@datatable, simple: true) %>
```

# DSL

The effective_datatables DSL is made up of 5 sections: `collection`, `datatable`, `filters` `bulk_actions`, `charts`

As well, a datatable can be initialized with `attributes`.

## attributes

When initialized with a Hash, that hash is available throughout the entire datatable as `attributes`.

You can call the attributes from within the datatable as `attributes` or within a partial/view as `@datatable.attributes`.

These attributes are serialized and stored in an encrypted data attribute. Objects won't work. Keep it simple.

Attributes cannot be changed by search, filter, or state in any way. They're guaranteed to be the same as when first initialized.

```ruby
class PostsController < ApplicationController
  def index
    @datatable = PostsDatatable.new(user_id: current_user.id, admin: true)
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
  scope = Post.includes(:user).where(created_at: filters[:start_date]...filters[:end_date])
  scope = scope.where(user_id: attributes[:user_id]) if attributes[:user_id]
  scope
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
    .group_by { |time_entry| "#{time_entry.client_id}_#{time_entry.created_at.strftime('%b').downcase}" }

  Client.all.map do |client|
    [client] + [:jan, :feb, :mar, :apr, :may, :jun, :jul, :aug, :sep, :oct, :nov, :dec].map do |month|
      entries = time_entries["#{client.id}_#{month}"] || []

      calc = TimeEntryCalculator.new(entries)

      [calc.duration, calc.bill_duration, calc.overtime, calc.revenue, calc.cost, calc.net]
    end
  end
end
```

The collection block is responsible for applying any `attribute` and `filters` logic.

When an ActiveRecord collection, the `current_scope`, will be applied automatically by effective_datatables.

All searching and ordering is also done by effective_datatables.

Your collection method should not contain a `.order()`, or implement search in any way.

Sometimes it's handy to call `.reorder(nil)` on a scope.

## datatable

The `datatable do ... end` block configures a table of data.

Initialize the datatable in your controller or view, `@datatable = PostsDatatable.new(self)`, and render it in your view `<%= render_datatable(@datatable) %>`

## col

This is the main DSL method that you will interact with.

`col` defines a 1:1 mapping between the underlying SQL database table column or Array index to a frontend jQuery Datatables table column. It creates a column.

Each column's search and sorting is performed on its underlying value, as per the collection.

It accepts one optional block used to format the value after any search or sorting is done.

The following options are available:

```ruby
action: :show|:edit|false  # Render as a link to this action. edit -> show by default
as: :string|:integer|etc   # Sets the type of column initializing defaults for search, sort and format
col_class: 'col-green'     # Sets the html class to use on this column's td and th
label: 'My label'          # The label for this column
partial: 'posts/category'  # Render this column with a partial. The local will be named resource
partial_as: 'category'     # The name of the object's local variable, otherwise resource
responsive: 10000          # Controls how columns collapse https://datatables.net/reference/option/columns.responsivePriority

# Configure the search behavior. Autodetects by default.
search: false
search: :string
search: { as: :string, fuzzy: true }
search: User.all
search: { as: :select, collection: User.all, multiple: true, include_null: 'All Users' }
search: { collection: { 'All Books' => Book.all, 'All Shirts' => Shirt.all}, polymorphic: true }

sort: true|false           # Should this column be orderable. true by default
sql_column: 'posts.rating' # The sql column to search/sort on. Only needed when doing custom selects or tricky joins.
visible: true|false        # Show/Hide this column by default
```

The `:as` setting determines a column's search, sort and format behaviour.

It is auto-detected from an ActiveRecord collection's SQL datatype, and set to `:string` for any Array-based collections.

Valid options for `:as` are as follows:

`:boolean`, `:currency`, `:datetime`, `:date`, `:decimal`, `:duration`, `:email`, `:float`, `:integer`, `:percent`, `:price`, `:resource`, `:string`, `:text`

These settings are loosely based on the regular datatypes, with some custom effective types thrown in:

- `:currency` expects the underlying datatype to be a Float.
- `:duration` expects the underlying datatype to be an Integer representing the number of minutes. 120 == 2 hours
- `:email` expects the underlying datatype to be a String
- `:percent` expects the underlying datatype to be an Integer * 1000. 50000 == 50%. 50125 == 50.125%.
- `:price` expects the underlying datatype to be an Integer representing the number of cents. 5000 == $50.00
- `:resource` can be used for an Array based collection which includes an ActiveRecord object

The column will be formatted as per its `as:` setting, unless a custom format block is present:

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

If the column name matches a `belongs_to`, `has_many` or other association on your collection class, like `col :user`, the column will be created as a resource column.

A resource column will try to link to the show/edit/destroy actions of its objects, based on permissions and routes. You can alter this behaviour with the `action:` variable.

You can also use the joined syntax, `col 'user.email'` to create a column for just this one field.

This feature is only working with `belongs_to` and you need to add the `.joins(:user)` to the collection do ... end block yourself.

## val

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

All searching and sorting for this column will be performed on this computed value.

This is implemented as a full Array search/sort and is much slower for large datasets than a paginated SQL query

The `.format do ... end` block can then be used to apply custom formatting.

## bulk_actions_col

Creates a column of checkboxes for use with the `bulk_actions` section.

Each input checkbox has a value equal to its row `object.to_param` and gets submitted as an Array of ids, `params[:ids]`

Use these checkboxes to select all / none / one or more rows for the `bulk_actions do ... end` section (below).

You can only have one `bulk_actions_col` per datatable.

## actions_col

When working with an ActiveRecord based collection, this column will consider the `current_user`'s authorization, and generate links to edit, show and destroy actions for any collection class.

The authorization method is configured via the `config/initializers/effective_datatables.rb` initializer file.

There are just a few options:

```ruby
btn_class: 'btn-sm btn-outline-primary'
show: true|false
edit: true|false
destroy: true|false
visible: true|false
actions_partial: :dropleft
inline: true|false
```

Each object is checked individually for authorization.

The arguments to `actions_col` are passed through to the `effective_resource` gem's [render_resource_actions](https://github.com/code-and-effect/effective_resources/blob/master/app/helpers/effective_resources_helper.rb#L57).

It's all very complicated.

If you just want to override this entire column with your own actions implementation, you can pass `actions_col partial: 'my_partial'` and roll your own.

Otherwise, use the following block syntax to add additional actions. This helper comes from `effective_bootstrap` gem.

```ruby
actions_col do |post|
  dropdown_link_to('Approve', approve_post_path(post) data: { method: :post, confirm: "Approve #{post}?"})
end
```

Any `data-remote` actions will be hijacked and performed as inline ajax by datatables.

If you'd like to opt-out of this behavior, use `actions_col(inline: false)` or add `data-inline: false` to your action link.

## length

Sets the default number of rows per page. Valid lengths are `5`, `10`, `25`, `50`, `100`, `250`, `500`, `:all`

When not specified, effective_datatables uses the default as per the `config/initializers/effective_datatables.rb` or 25.

```ruby
length 100
```

## order

Sets the default order of table rows. The first argument is the column, the second the direction.

The column must exist as a `col` or `val` and the direction is either `:asc` or `:desc`.

When not specified, effective_datatables will sort by the first defined column.

```ruby
order :created_at, :asc|:desc
```

## reorder

Enables drag-and-drop row re-ordering.

Only works with ActiveRecord collections.

The underlying field must be an Integer, and it's assumed to be a sequential list of unique numbers.

When a drag and drop is completed, a POST request is made to the datatables#reorder action that will update the indexes.

Both zero and one based lists will work.

```ruby
reorder :position
```

Using `reorder` will sort the collection by this field and disable all other column sorting.

## aggregate

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

You can also override an individual columns aggregate calculation as follows:

```ruby
col :created_at, label: 'Created' do |post|
  time_ago_in_words(post.created_at)
end.aggregate { |values, column| distance_of_time_in_words(values.min, values.max) }
```

In the above example, `values` is an Array containing all row's values for one column at a time.

## filters

Creates a single form with fields for each `filter` and a single radio input field for all `scopes`.

The form is submitted by an AJAX POST action, or, in some advanced circumstances (see Dynamic Columns below) as a regular POST or even GET.

Initialize the datatable in your controller or view, `@datatable = PostsDatatable.new(self)`, and render its filters anywhere with `<%= render_datatable_filters(@datatable) %>`.

## scope

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

## filter

Each filter has a name and a default/fallback value. If the form is submitted blank, the default values are used.

effective_datatables looks at the default value, and tries to cast the incoming (String) value into that datatype.

This ensures that calling `filters[:name]` always return a value. The default can be nil.

You can override the parsing on a per-filter basis.

Unlike `scope`s, the filters are NOT automatically applied to your collection. You are responsible for considering `filters` in your collection block.

```ruby
filters do
  filter :start_date, Time.zone.now-3.months, required: true
  filter :end_date, nil, parse: -> { |term| Time.zone.local(term).end_of_day }
  filter :user, current_user, as: :select, collection: User.all
  filter :year, 2018, as: :select, collection: [2018, 2017], label: false, include_blank: false
  filter :year_group, '2018', as: :select, grouped: true, collection: { 'Years' => [['2017', 2017], ['2018', 2018]], 'Months' => [['January', 1], ['February', 2]] }
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
as: :select|:date|:boolean      # Passed to form
label: 'My label'               # Label for this form field
parse: -> { |term| term.to_i }  # Parse the incoming term (string) into whatever datatype
required: true|false            # Passed to form
```

Any other option given will be yielded to EffectiveBootstrap as options.

## bulk_actions

Creates a single dropdown menu with a link to each action, download or content.

Along with this section, you must put a `bulk_actions_col` somewhere in your `datatable do ... end` section.

## bulk_action

Creates a link that becomes clickable when one or more checkbox/rows are selected as per the `bulk_actions_col` column.

A controller action must be created to accept a POST with an array of selected ids, `params[:ids]`.

This is a pass-through to `link_to` and accepts all the same options, except that the method `POST` is used by default.

You can also specify `data-method: :get` to instead make a `GET` request with the selected ids and redirect the browser link a normal link.

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

or if using [effective_resources](https://github.com/code-and-effect/effective_resources):

```ruby
include Effective::CrudController
```

and in your model

```ruby
def approve!
  update_attributes!(status: :approved)
end
```

## bulk_action_divider

Inserts a menu divider `<li class='divider' role='separator'></li>`

## bulk_download

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

## bulk_action_content

Blindly inserts content into the dropdown.

```ruby
bulk_actions do
  bulk_action_content do
    content_tag(:li, 'Something')
  end
end
```

Don't actually use this.

# Charts

Create a [Google Chart](https://developers.google.com/chart/interactive/docs/quick_start) based on your searched collection, filters and attributes.

No javascript required. Just use the `chart do ... end` block and return an Array of Arrays.

The first collection, `collection` is the raw results as returned from the `collection do` block.

The second collection, `searched_collection` is the results after the table's search columns have been applied, but irregardless of pagination.

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

  chart :posts_per_user, 'ColumnChart' do |collection, searched_collection|
    measured_posts = if search.present?
      ["Posts with #{search.map { |k, v| k.to_s + ' ' + v.to_s }.join(',')}", searched_collection.length]
    else
      ['All Posts', collection.length]
    end

    [['Posts', 'Count'], measured_posts] +
    searched_collection.group_by(&:user).map { |user, posts| [user.last_name, posts.length] }
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
<%= render_datatable_charts(@datatable) %>
```

All options passed to `chart` are used to initialize the chart javascript.

By default, the only package that is loaded is `corechart`, see the `config/initializers/effective_datatables.rb` file to add more packages.

# Inline

Any datatable can be used as an inline datatable, to create, update and destroy resources without leaving the current page.

If your datatable is already working with `actions_col` and being rendered from an `Effective::CrudController` controller, all you need to do is change your view from `render_datatable(@datatable)` to `render_datatable(@datatable, inline: true)`.

Click here for a [Inline Live Demo](https://effective-datatables-demo.herokuapp.com/things) and here for an [Inline Code Example](https://github.com/code-and-effect/effective_datatables_demo)
(only the `thing` data model and `things_datatable` are being used inline)

To use effective_datatables as an inline CRUD builder, you will be relying heavily on [effective_resources](https://github.com/code-and-effect/effective_resources) which is a dependency of this gem. I would also recommend you install [effective_developer](https://github.com/code-and-effect/effective_developer) to get access to some scaffolds and generators. It's not required but I'm gonna use them in this example.

Here is how I build rails models for inline datatable CRUD operations:

1. Create a new model file `app/models/thing.rb`:

```ruby
class Thing < ApplicationRecord
  belongs_to :user

  effective_resource do
    title           :string
    description     :text
    timestamps
  end

  scope :deep, -> { includes(:user) }
  scope :sorted, -> { order(:title) }

  def to_s
    title
  end
end
```

The `effective_resource do` block comes from the [effective_resources](https://github.com/code-and-effect/effective_resources) gem and is used to build any permitted_params.

2. Generate a migration. Run `rails generate effective:migration things` to create a migration based off the model file then `rails db:migrate`.

3. Scaffold the rest. Run `rails generate effective:scaffold_controller things` which will create:

- A controller `app/controllers/things_controller.rb`:

```ruby
class ThingsController < ApplicationController
  include Effective::CrudController
end
```

The Effective::CrudController comes from [effective_resources](https://github.com/code-and-effect/effective_resources) gem and handles the standard 7 CRUD actions and member and collection actions. It is opinionated code that follows rails conventions. It considers the `routes.rb` and `ability.rb` or other authorization, to find all available actions.

- A datatable `app/datatables/things_datatable.rb`:

```ruby
class ThingsDatatable < Effective::Datatable
  datatable do
    col :title
    col :description
    actions_col
  end

  collection do
    Thing.deep.all
  end
end
```

This is an ordinary datatable. As long as it's an ActiveRecord collection, inline crud will work.

- A view partial `app/views/things/_thing.html.haml`:

```ruby
%table.table
  %tbody
    %tr
      %th Title
      %td= thing.title
    %tr
      %th Description
      %td= thing.description
```

This file is what rails uses when you call `render(thing)` and what datatables uses for the inline `show` action. It's important that its called `_thing.html`.

- A form partial `app/views/things/_form.html.haml`:

```ruby
= effective_form_with(model: thing) do |f|
  = f.text_field :title
  = f.text_area :description
  = f.submit
```

The `effective_form_with` comes from [effective_bootstrap](https://github.com/code-and-effect/effective_bootstrap) gem and is a drop-in replacement for the newer `form_with` syntax. It's really good, you should use it, but an ordinary `form_with` will work here just fine.

This `_form.html` is an effective gems convention. This file shoudl exist for each of your resources.

- A resources entry in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  resources :things do
    post :approve, on: :member
    post :reject, on: :member
  end
end
```

Above we have `resources :things` for the 7 crud actions. And we add two more member actions, which datatables will call `approve!` or `reject!` on thing.


4. Render in the view. Create an `app/views/things/index.html.haml` and call `render_datatable(@datatable, inline: true)` or `render_inline_datatable(@datatable).

```ruby
= render_datatable(@datatable, inline: true)
```

Your datatable should now have New, Show, Edit, Approve and Reject buttons. Click them for inline functionality.

## Troubleshooting Inline

If things aren't working, try the following:

- Double check your javascripts:

```ruby
//= require jquery3
//= require popper
//= require bootstrap
//= require effective_bootstrap
//= require effective_datatables
//= require jquery_ujs
```

The inline functionality requires one of sprockets jquery_ujs, sprockets rails_ujs or webpack @rails/ujs libraries.

- Double check your stylesheets:

```ruby
@import 'bootstrap';
@import 'effective_bootstrap';
@import 'effective_datatables';
```

- Make sure your datatable is not being rendered inside a `<form>...</form>` tag. It will display a javascript console error and won't work.

- Double check your `resources :things` are in `routes.rb` in the same namespace as the controller, and that you have authorization for those actions in `ability.rb` or whatever your `config/initializers/effective_datatables.rb` `config.authorization_method` returns.

## A note on how it works

We use good old `rails_ujs` for all inline actions.

When inline, any of the actions_col actions, as well as the New button, will be changed into `data-remote: true` actions.

The [inline_crud javascript](https://github.com/code-and-effect/effective_datatables/blob/master/app/assets/javascripts/effective_datatables/inline_crud.js.coffee) handles fetching the form, or view partial and expanding/collapsing the appropriate row of the datatable.

When an inline action is clicked, effective_datatables will make an AJAX request to the server, which could be received by an `Effective::CrudController` that will handle the `.js` format, and respond_with the appropriate [rails_ujs .js.erb views](https://github.com/code-and-effect/effective_resources/tree/master/app/views/application).


# Extras

The following commands don't quite fit into the DSL, but are present nonetheless.

## simple

To render a simple table, without pagination, sorting, filtering, export buttons, per page, and default visibility:

```
<%= render_datatable(@datatable, simple: true) %>
```

## index

If you just want to render a datatable and nothing else, there is a quick way to skip creating a view:

```ruby
class PostsController < ApplicationController
  def index
    render_datatable_index PostsDatatable.new(self)
  end
end
```

will render `views/effective/datatables/index` with the assigned datatable.

# Advanced Search and Sort

The built-in search and ordering can be overridden on a per-column basis.

The only gotcha here is that you must be aware of the type of collection.

## With ActiveRecord collection

In the case of a `col` and an ActiveRecord collection:

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
    # column is this column's options Hash
    # sql_column is the column[:sql_column]
    categories = current_user.post_categories.where(id: term.to_i)

    collection.where(post_category_id: categories)  # Must return an ActiveRecord scope
  end.sort do |collection, direction, column, sql_column|
    collection.joins(:post_category).order(:post_category => :title, direction)
  end
end
```

If you run into issues where `collection` here is an Array, you're probably using some joins in your `collection do ... end` block.

If `column[:sql_column].blank?` then this `col` has fallen back to being a `val`.

Try adding `col :post_category, sql_column: 'post_categories.title'`

## With Array collection

And in the case of a `col` with an Array collection, or any `val`:

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
  end.sort do |collection, direction, column, index|
    if direction == :asc
      collection.sort! { |a, b| a[index] <=> b[index] }
    else
      collection.sort! { |a, b| b[index] <=> a[index] }
    end
  end
end
```

The search and sort for each column will be merged together to form the final results.

## Default search collection

When using a `col :comments` type belongs_to or has_many column, a search collection for that class will be loaded.

Add the following to your related model to customize the search collection:

```ruby
class Comment < ApplicationRecord
  scope :datatables_filter, -> { includes(:user) }
end
```

Datatables will look for a `datatables_filter` scope, or `sorted` scope, or fallback to `all`.

If there are more than 500 max records, the filter will fallback to a `as: :string`.

## Dynamic Column Count

There are some extra steps to be taken if you want to change the number of columns based on `filters`.

Unfortunately, the DataTables jQuery doesn't support changing columns, so submitting filters needs to be done via POST instead of AJAX.

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

    actions_col
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

Check whether the datatable has records by calling `@datatable.present?` and `@datatable.blank?`.

## Override javascript options

The javascript options used to initialize a datatable can be overriden as follows:

```ruby
render_datatable(@datatable, input_js: { dom: "<'row'<'col-sm-12'tr>>", autoWidth: true })
```

```ruby
render_datatable(@datatable, input_js: { buttons_export_columns: ':visible:not(.col-actions)' })
```

Please see [datatables options](https://datatables.net/reference/option/) for a list of initialization options.

You don't want to actually do this!

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

## Render outside of view

You can render a datatable outside the view.

Anything you pass to the `rendered` method is treated as view/request params.

You can test filters and scopes by passing them here.

```
post = Post.create!
datatable = PostsDatatable.new.rendered(end_date: Time.zone.now+2.days, current_user_id: 1)

assert_equal 1, datatable.collection.count
assert_equal [post], datatable.collection
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

# License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
