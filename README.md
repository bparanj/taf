Tagging from Scratch in Rails 5 using Zurb Foundation

## Libraries Used

- Zurb Foundation  6.2.3
- Modernizr        3.3.1

Zurb Foundation is a CSS framework. Modernizr tells you what HTML, CSS and JavaScript features the user’s browser has to offer.

## Basic Setup

Create a new Rails 5 project.

```
rails new taf
```

Add:

```ruby
gem 'foundation-rails'
```

to Gemfile and run:

```
bundle
```

Install Zurb Foundation by running the generator.

```
rails g foundation:install
```

Say, yes to override the application.html.erb. Create the tag model:

```
rails g model tag name
```

Create the article model:

```
rails g model article author content:text
```

Create the tagging model:

```
rails g model tagging article:belongs_to tag:belongs_to
```

Migrate the database:

```
rails db:migrate
```

If you use `belongs_to` in the rails generator, Rails will automatically add indexes to the foreign keys. You can see it in the schema.rb:

```ruby
create_table "taggings", force: :cascade do |t|
  t.integer  "article_id"
  t.integer  "tag_id"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["article_id"], name: "index_taggings_on_article_id"
  t.index ["tag_id"], name: "index_taggings_on_tag_id"
end
```

Define the assocations between article and tag models:

```ruby
class Tag < ApplicationRecord
  has_many :taggings
  has_many :articles, through: :taggings
end
```

```ruby
class Article < ApplicationRecord
  has_many :taggings
  has_many :tags, through: :taggings
end
```

Since we used the `belongs_to` in the rails generator for tagging model, we have:

```ruby
class Tagging < ApplicationRecord
  belongs_to :article
  belongs_to :tag
end
```

## Tagging an Article

Add tag related methods to article model.

```ruby
def all_tags=(names)
  self.tags = names.split(',').map do |name|
    Tag.where(name: name.strip).first_or_create!
  end
end

def all_tags
  self.tags.map(&:name).join(', ')
end
```

Create the articles controller with index and create actions.

```
rails g controller articles index create
```

The user enters value for the `all_tags` virtual attribute in the view, so include it in the strong parameters.

```ruby
private

def article_params
  params.require(:article).permit(:author, :content, :all_tags)
end
```

Create the form with a text field for tags. We will use AJAX to create an article. In `app/views/articles/_form.html.erb`:

```rhtml
<div class="row">
  <div class="large-10 large-centered columns">
     <%= form_for(@article, remote: true) do |f| %>
      <div class="row column log-in-form">
        <h4 class="text-center">Tag Me!</h4>
        <label>Author
          <%= f.text_field :author %>
        </label>
        <label>Body
          <%= f.text_area :content, rows: 5 %>
        </label>
        <label>Tags
          <%= f.text_field :all_tags, placeholder: "Tags separated with comma" %>
        </label>
	    <%= f.submit "Submit", class: "button"%>
      </div>
    <% end %>
  </div>
</div>
```

The `remote: true` attribute must be specified to make an AJAX call to the create action in articles controller. Here is the app/views/articles/index.html.erb:

```rhtml
<div class="row">
  <div class="large-8 columns">
    <%= render  "form" %>
  </div>
</div>
```

Define the resources in the routes.rb:

```ruby
Rails.application.routes.draw do
  resources :articles
  root 'articles#index'
end
```

For the css in articles.scss, refer the source code repository for this article [taf](https://github.com/bparanj/taf 'tagging in rails 5'). Run the rails server. When we create a new article, we get the error:

```
ActionController::RoutingError (No route matches [GET] "/javascripts/vendor/modernizr.js"):
```

Add:

```ruby
gem 'modernizr-rails'
```

to Gemfile and run bundle. In layout, add:

```rhtml
<%= javascript_include_tag :modernizr %>
```

in the head section. Otherwise, you will have problems loading modernizr.js. Restart the server. You will now get the error:

```
Sprockets::Rails::Helper::AssetNotPrecompiled in Articles#index
Asset was not declared to be precompiled in production.
Add `Rails.application.config.assets.precompile += %w( modernizr.js )` to `config/initializers/assets.rb` and restart your server
```

Add the above declaration and restart the server. Create the file app/views/articles/create.js.erb:

```rhtml
var new_post = $("<%= escape_javascript(render(partial: @article))%>").hide();
$('#articles').prepend(new_post);
$('#article_<%= @article.id %>').fadeIn('slow');
$('#new_article')[0].reset();
```

Implement the create action:

```ruby
def create
  @article = Article.new(article_params)
  respond_to do |format|
    if @article.save
      format.js
    else
      format.html { render root_path }
    end
  end
end
```

Create _article.html.erb to render the article:

```
<div id="article_<%= article.id %>">
  <div class="large-12 columns border border-box glassy-bg mt pt">
    <strong><%= h(article.author) %></strong><br />
    <sup class="text-muted">From <%= time_ago_in_words(article.created_at)%></sup><br />
    <div class="mb pb">
      <%= h(article.content) %>
    </div>
    <div class="tags">
      <%=raw tag_links(article.all_tags)%>
    </div>
  </div>
</div>
```

## Search by Tag

Implement the method to find all articles that is tagged with a certain tag in article.rb:

```ruby
def self.tagged_with(name)
  Tag.find_by(name: name).articles
end
```

Change the articles index action to handle the search:

```ruby
@articles = if params[:tag]
  Article.tagged_with(params[:tag])
else
  Article.all
end
```

Declare the route for searching.

```ruby
get 'tags/:tag', to: 'articles#index', as: 'tag'
```

Now you can see all the articles that has been tagged by a specific tag by clicking on any tag.

## Tag Cloud

Implement the number method in Tag.

```ruby
class Tag < ApplicationRecord
  has_many :taggings
  has_many :articles, through: :taggings
  
  def self.number
    self.select("name, count(taggings.tag_id) as count").joins(:taggings).group("taggings.tag_id")
  end
end
```

Implement the `tag_cloud` method in articles helper.

```ruby
module ArticlesHelper
  def tag_links(tags)
    tags.split(",").map{|tag| link_to tag.strip, tag_path(tag.strip) }.join(", ") 
  end

  def tag_cloud(tags, classes)
    max = tags.sort_by(&:count).last
    tags.each do |tag|
      index = tag.count.to_f / max.count * (classes.size-1)
      yield(tag, classes[index.round])
    end
  end
end
```

Add the css to tags.scss:

```css
.css1 { font-size: 1.0em;}
.css2 { font-size: 1.2em;}
.css3 { font-size: 1.4em;}
.css4 { font-size: 1.6em;}
```

Create an article with some tags. Change index to display the articles:

```rhtml
<div class="row mt pt">
  <div class="large-5 columns">
    <div class="top-pad glassy-bg">
      <%= render 'form' %>
    </div>
    <div class="tags-cloud glassy-bg">
      <h4>Tags Cloud</h4>
      <% tag_cloud Tag.number, %w{css1 css2 css3 css4} do |tag, css_class| %>
        <%= link_to tag.name, tag_path(tag.name), class: css_class %>
      <% end %>
    </div>
  </div>
  <div class= "large-7 columns" id="posts">
    <%= render partial: @articles.reverse %>
  </div>
</div>
```

You can download the source code for this article from [Tagging in Rails 5](https://github.com/bparanj/taf 'Tagging in Rails 5').

## Summary

In this article, you learned how to develop tagging a single model from scratch in Rails 5 using Zurb Foundation and Modernizr.

## Resources

[Modernizr](https://modernizr.com 'Modernizr')
[Tagging from Scratch in Rails 4](https://www.sitepoint.com/tagging-scratch-rails/ 'Tagging from Scratch in Rails 4')