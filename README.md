# CollabBlogs

## Web App Description

CollabBlogs is an example of a Rails app that facilitates collaborative writing. The basic functionalities of the app are as follows.

- Guest users (non-logged in users) can read non-restricted posts.
- A restricted post is a post that can be viewed by the creator and the collaborators chosen by the creator. If there is no collaborator, only the creator can see the post.
- A post can be edited by many users, if the post creator chooses to collaborate with other users.
- Logged-in users can create posts.
- A post can only be deleted by its creator.
- An administrator user can do anything he/she wants.

## Requirements

Make sure you have the following installed:

- [Ruby](http://www.ruby-lang.org/en/downloads/) 2.0
- [Bundler](http://bundler.io/) (can be installed via `gem install bundler`)
- [Rails](http://rubyonrails.org/download) 4.0 (can be installed via `gem install rails`)

*Although SQLite is used throughout this app, you can pick any other database you prefer (MySQL, PostgreSQL, etc.) when you build your own app.*

Installing via [Rails Installer](http://railsinstaller.org/):

1. [Download and execute the installer](http://railsinstaller.org/). The installer already includes RVM, Ruby 1.9.3, and Rails 3.2.

1. Install Ruby 2.0 and use it as default
    ```bash
    rvm install 2.0.0
    rvm use 2.0.0 --default
    ```

1. Install Rails 4.0
    ```bash
    gem install rails
    ```

## Running App, Tests, and Specs

### Running App

```bash
rake db:migrate
rake db:seed
rails s
```

### Running Tests

```bash
rake db:migrate RAILS_ENV=test
rake test
```

### Running Specs

```bash
rake db:migrate RAILS_ENV=spec
rake spec
```

## Steps to Recreate the App

### Preparing Initial Structure

In this section, you will setup authentication using Devise, as well as the models needed for our CollabBlogs web application.

1. Create a new Rails 4.0 app
    ```bash
    rails new collab-blogs
    ```

1. Add Devise and CanCan to `Gemfile`
    ```ruby
    # Gemfile
    # ...
    gem 'rails', '4.0.0'
    gem 'devise', '3.0.0.rc'
    gem 'cancan', '1.6.0'
    gem "select2-rails" # we are going to need this for forms
    # ...
    ```
  After that, run `bundle` to ensure that dependencies are met.

1. Setup Devise
    ```bash
    rails g devise:install
    rails g devise User
    ```
    Edit Devise user migration to include `admin` flag
    ```ruby
    # db/migrate/<timestamp>_devise_create_user.rb
    # ...
    t.boolean :admin, null: false, default: false

    ## Database authenticatable
    t.string :email,              :null => false, :default => ""
    # ...
    ```


1. Edit Devise routes. Add the following code snippet to `config/routes.rb`:
    ```ruby
    # config/routes.rb
    # ...
    authenticated :user do
      root :to => 'posts#index', as: :authenticated_root
    end

    root :to => "posts#index"
    # ...
    ```

1. Allow necessary parameters for Devise controllers
    ```ruby
    before_filter :configure_permitted_parameters, if: :devise_controller?
 
    protected
 
    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_in) do |u|
        u.permit(:username, :email)
      end
      devise_parameter_sanitizer.for(:sign_up) do |u|
        u.permit(:name, :email, :password, :password_confirmation)
      end
      devise_parameter_sanitizer.for(:account_update) do |u|
        u.permit(:name, :email, :password, :password_confirmation, :current_password)
      end
    end
    ```

1. Run database migrations on your terminal using `rake db:migrate`

1. Check if the authentication works.
    - Try to sign up at <http://localhost:3000/users/sign_up>
    - Try to sign in at <http://localhost:3000/users/sign_in>

1. Create `Post` scaffold and `Collaboration` model
    ```bash
    rails g scaffold post user:references title content:text restricted:boolean
    rails g model collaboration user:references post:references
    ```

    Edit the migrations as you wish.
    ```ruby
    # db/migrate/<timestamp>_create_posts.rb
    # ...
    t.references :user, null: false
    t.string :title, limit: 80, null: false
    t.text :content, null: false, default: ""
    t.boolean :restricted, null: false, default: false
    # ...

    # db/migrate/<timestamp>_create_collaborations.rb
    # ...
    t.references :user, null: false
    t.references :post, null: false
    # ...
    ```

    Change the `PostsController`'s `create` action so that it assigns current_user as the post owner.
    ```ruby
    # app/controllers/posts_controller.rb
    # ...
    # POST /posts
    # POST /posts.json
    def create
      @post = Post.new(post_params)
      @post.user = current_user
    # ...
    ```

    Make sure that `Post` and `Collaboration` models declare enough validations and some database relationships.
    ```ruby
    # app/models/collaboration.rb
    class Collaboration < ActiveRecord::Base
      belongs_to :user
      belongs_to :post
    end

    # app/models/collaboration.rb
    class Post < ActiveRecord::Base
      belongs_to :user
      has_many :collaborations
      has_many :collaborators, through: :collaborations, source: :user

      validates_presence_of :title, :content
    end
    ```

1. Run database migrations on your terminal using `rake db:migrate`
1. You can seed the database too using `rake db:seed` if you wish (see `db/seeds.rb` for examples)

### Building Access Control Rules in *ability.rb*

The access control rules are declared in `app/models/ability.rb`. Run the following command in your Terminal so that CanCan generate the `ability.rb` file for you.

```bash
rails g cancan:ability
```

#### User Abilities for Collaborative Editing

The CanCan Ability class is the place where most of the access control rules are defined. It should include CanCan::Ability module in order to make it work. The class should also be provided with a constructor that accepts `current_user` (passed from the Rails controllers) as a parameter.

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
  end
end
```

Within the Ability constructor, some methods (`can` and `cannot`) can be used for declaring the rules. For simplicity, all of the examples below use `can`.

##### Simple Abilities

Let's pick one simple rule we can define using CanCan, **"Logged-in users can create posts."** In typical Rails controllers, creating a post requires access to `new` and `create` actions. Therefore, the ability should allow logged-in users to access both actions. To do so, use `can [:new, :create], Post` within the CanCan initializer.

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    if user && user.persisted? # Logged in user
      # Logged-in users can create posts
      can [:new, :create], Post
    end
  end
end
```

We can also add another rule for **"A post can only be deleted by its creator."** The way we declare the ability for that is similar to the previous rule. The difference is that a hash containing a simple condition is used (user ID of the post should be the same as the `current_user`'s ID)

```ruby
# app/models/ability.rb
# ...
can [:new, :create], Post
# A post can only be deleted by its creator.
can :destroy, Post, user_id: user.id
# ...
```

Another rule that looks similar would be allowing administrators to do anything.

```ruby
# app/models/ability.rb
# ...
if user && user.persisted? # Logged in user
  if user.admin?
    can :manage, :all
  else
    # non-admin abilities like we already have above
    # ...
  end
end
```

Notice that `:all` is used instead of a class.

Do you see the pattern? Feel free to try implementing the ability for **"Guest users (non-logged in users) can read non-restricted posts."**

By now, we can see that `can` (and `cannot`) takes two to three arguments. The first argument is an action or the list of actions to be permitted (or prohibited). The second argument takes a resource class (or sometimes a symbol) that we would like to restrict. The third argument, which is optional, takes a hash of simple conditions. That hash will be used for view helpers and building queries using `Model#accessible_by` in controllers, which will be discussed in another section.

##### Slightly Complex Abilities

This section is important if you want to have SQL subselect or joins in your rules, or when you want to make use of Ability class to help you build SQL queries (using `Model#accessible_by`). For that purpose, use an array containing SQL conditions and values to be sanitized.

For example, we can write

```ruby
can :destroy, Post, user_id: user.id
```

as

```ruby
can :destroy, Post, ['user_id = ?', user.id]
```

Unfortunately, this new rule is not quite the same as the old one. The SQL query will only help building queries using `Model#accessible_by`; it does not do any view checks. When such SQL-based rule is used, it is mandatory to implement a block that means the same, for the purpose of checking views (using `can?` or `cannot?`).

```ruby
can :destroy, Post, ['user_id = ?', user.id] do |post|
  post.user_id == user.id
end
```

Now, the above rule is the same as the one that we have before, `can :destroy, Post, user_id: user.id`

There is one thing to remember that the block is evaluated when an instance of post is passed for checking. This is why we do not do this:

```ruby
can :manage, :all do |project|
  user.admin? # this won't always get called
end
```

Instead, we do this:

```ruby
if user.admin?
  can :manage, :all
else
  # ...
end
```

Now that we know how to use SQL conditions and blocks to implement abilities, let's try to use them for abilities that requires subselects like below:

- A restricted post is a post that can be viewed by the creator and the collaborators chosen by the creator. If there is no collaborator, only the creator can see the post.
- A post can be edited by many users, if the post creator chooses to collaborate with other users.

The first set of rule is related to `index` and `show` actions in typical Rails controller. In those actions, we need to make sure that:

- Non-restricted posts are viewable (related to one of the other rules), or
- Posts created by the currently logged-in user is viewable, or
- If the post is restricted, the posts' collaborators can view the posts.

```ruby
# for logged-in users
#...
indexable_condition = <<-EOC
restricted = ? OR posts.user_id = ? OR (restricted = ? AND EXISTS
  (SELECT * FROM collaborations WHERE collaborations.post_id = posts.id AND collaborations.user_id = ?))
EOC
can [:index, :show], Post, [indexable_condition, false, user.id, true, user.id] do |post|
  !post.restricted? || post.user_id == user.id ||
    (post.restricted? &&
     post.collaborations.where(user_id: user.id).present?)
end
```

The second set of rule is very similar to above. Feel free to try implementing it yourself.


### Checking Views Based on Defined Abilities

`can?` and `cannot?` are the two CanCan view helpers that are very often used. Below are some examples of the usages for edit post links (see in `app/views/posts/index.html.erb` or `app/views/posts/show.html.erb`).

```html
<% if can? :edit, @post %>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>
```

```html
<% if cannot? :edit, @post %>
  In order to edit this post, ask the owner to provide you access.
<% end %>
```

Run your Rails server (`rails s`) if you have not done so, and check if your views are displayed according to the rules. If you would like to see more, check out the views under `app/views/`. In those views, only the `can?` method is being used for simplicity.

### Authorizing Controllers

We already hide the views according to the defined rules. We also need to protect our controllers using the same rules.

```ruby
# app/controllers/posts_controller.rb
# ...
def edit
  authorize! :edit, @post
end

def update
  authorize! :update, @post
  respond_to do |format|
  # ...
end
# ...
```

Since adding the rules to every action can be tedious, you can use `authorize_resource`

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  authorize_resource

  # ...

  def edit
  # already authorized
  end

  def update
  # already authorized
  respond_to do |format|
  # ...
  end

  # ...
end
```


If you need to ensure authorization check are done in the `PostsController`, use `check_authorization`

```ruby
# app/controllers/posts_controller.rb
class PostsControllers < ApplicationController
  check_authorization
  # ...
end
```

On index action, authorization is not needed. To skip authorization check on certain actions, use `skip_authorization_check`

```ruby
# app/controllers/posts_controller.rb
class PostsControllers < ApplicationController
  check_authorization
  skip_authorization_check only: [:index]
  # ...
end
```

If you need to check authorization on all controllers, do so on the ApplicationController except on the Devise controllers.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery
  check_authorization :unless => :devise_controller?
  # ...
end
```

### Filtering Posts Based on Abilities

For the `index` action, we can build our own scopes to filter the posts. If that way is used, it will create duplication with the existing CanCan abilities. Luckily, CanCan provides model scope for filtering based on defined abilities and the actions.

```ruby
# app/controllers/posts_controller.rb
def index
  @posts = Post.accessible_by(current_ability, :index)
end
```

Remember that `Model#accessible_by` uses SQL query or hashes we provide in the previous sections. That method returns the familiar ActiveRecord query interface. You are free to chain and optimize it further.


### Handling Unauthorized Access

It would be nice if unauthorized access is handled, since now cases like that are highly possible. CanCan throws `CanCan::AccessDenied` when any controller authorization fails. In order to catch the exception in all controllers, use `rescue_from CanCan::AccessDenied` in ApplicationController and show an error message to the user.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
# ...
  check_authorization :unless => :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    if current_user.nil? # user is not logged in
      session[:next] = request.fullpath
      redirect_to login_url, :alert => "Please log in to continue."
    else
      if request.env["HTTP_REFERER"].present?
        redirect_to :back, :alert => exception.message
      else
        render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
      end
    end
  end
# ...
end
```

If your app is an API or web service, the above code only applies to html format. Say, we have a JSON format. To handle unauthorized access for JSON, simply render a message with forbidden status

```
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
# ...
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        # Same as above
        if current_user.nil?
          # ...
        else
          # ...
        end
      end

      format.json do
        # Show authorization error using JSON format
        render json: { message: "You are not allowed to access this resource." } , status: :forbidden
      end
    end
  end
# ...
end
```

If you want to log access denied, you can do it within the `rescue_from` block too.

```ruby
rescue_from CanCan::AccessDenied do |exception|
  Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

  respond_to do |format|
  # ...
  end
end
```

## Customizing Defaults in *current_ability*

The view helper methods (`can?`, `cannot?`, etc.) and the authorization methods in controllers (`authorize!`, etc.) make use of the `current_ability` method to apply the access control rules. You rarely need to customize `current_ability` for most cases. However, for the cases below, customizing the method is necessary.

- **Your Devise authenticated user method in controllers is not `current_user`.** If you prefer to use `current_account`, override the default `current_ability` method.
    ```ruby
    # app/controllers/application_controller.rb
    class ApplicationController < ActionController::Base
      #...

      private

      def current_ability
        # using current_account instead of current_user
        @current_ability ||= Ability.new(current_account)
      end
    end
    ```

- **You need to restrict access based on request-related values.** In some cases, you might want to block users with certain IP address. This can be done without CanCan, but if you do so, there will be two kinds of codes that do authorization: the IP address blocking and the defined abilities. These different ways can make your code complex. Customizing ability is a way to prevent such complexity.
    ```ruby
    # app/controllers/application_controller.rb
    class ApplicationController < ActionController::Base
      #...

      private
      def current_ability
        @current_ability ||= Ability.new(current_user, request.remote_ip)
      end
    end

    # app/models/ability.rb
    class Ability
      include CanCan::Ability

      def initialize(user, ip_address=nil)
        can :create, Post unless BLACKLIST_IPS.include? ip_address
        # ...
      end
    end
    ```

## Extras

CanCan does not only come with the neat way of doing authorization but also supplementary features to help you debug and test authorizations.

### Testing Abilities

Testing abilities can be done using several test frameworks, such as `Test::Unit`, [RSpec](http://rspec.info/), and [Cucumber](http://cukes.info/). In this section, using `Test::Unit` and RSpec for testing abilities will be explained.

#### Using *Test::Unit*

Here are examples of test using the default `Test::Unit`.

```ruby
test "user can destroy his/her own post" do
  user = User.create!(email: 'test@localhost.net', password: 'Asdfghj12', password_confirmation: 'Asdfghj12')
  ability = Ability.new(user)
  assert ability.can?(:destroy, Post.new(user: user))
  assert ability.cannot?(:destroy, Post.new)

  another_user = User.create!(email: 'test1@localhost.net', password: 'Asdfghj12', password_confirmation: 'Asdfghj12')
  assert ability.cannot?(:destroy, Post.new(user: another_user))
end
```

You can see more of those under the `test` folder. Feel free to run `rake test` on your terminal to execute the tests.

#### Using RSpec

Alternatively, you can also use RSpec. CanCan comes with RSpec matcher that makes it fun to test.

```ruby
require "cancan/matchers"
# ...
ability.should be_able_to(:destroy, Post.new(user: user))
ability.should_not be_able_to(:destroy, Post.new)
```

You can see more of the specs under the `spec` folder. To execute the specs, run `rspec spec` on your terminal.


### Debugging Abilities

For very particular cases, you might want to debug the defined abilities in Rails console, during test, or during development. In general, the following are steps to debug abilities.

1. Fetch any user and model you would like to debug.

    ```ruby
    user = User.first # any user you want to check
    post = Post.first # any model you want to check
    ability = Ability.new(user)
    ```
1. Check if ability behaves correctly for those records.<br/>
    Alternatively, you can check using model scope if the defined abilities can filter the correct list of accessible records.
    ```ruby
    # see if it behaves correctly
    ability.can?(:create, post)
    ability.can?(:create, Post)

    Post.accessible_by(ability) # see if returns the accessible records
    Post.accessible_by(ability).to_sql # see the SQL query
    ```
