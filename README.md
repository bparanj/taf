Tagging from Scratch in Rails 5 using Zurb Foundation

Libraries Used

Zurb Foundation Rails  6.2.3
Modernizr 

```
rails new taf
```

```
gem 'foundation-rails'
```

```
bundle
```

```
rails g model tag name
```

```
rails g model article author content:text
```

```
rails g model tagging article:belongs_to tag:belongs_to
```

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

Create assocations between articles and tags:

```ruby
class Tag < ApplicationRecord
  has_many :taggings
  has_many :articles, through: :taggings
end
```

```
class Article < ApplicationRecord
  has_many :taggings
  has_many :tags, through: :taggings
end
```

Since we used the belongs_to in the rails generator for tagging model, we have:

```
class Tagging < ApplicationRecord
  belongs_to :article
  belongs_to :tag
end
```

Add tag related methods to article model.

```
def all_tags=(names)
  self.tags = names.split(',').map do |name|
    Tag.where(name: name.strip).first_or_create!
  end
end

def all_tags
  self.tags.map(&:name).join(', ')
end
```

Install Zurb Foundation.

```
rails g foundation:install
```

Say, Yes to override the application.html.erb.

Create the articles controller.

```
rails g controller articles index create
```

The user enters value for the virtual attribute in the view, so include it in the strong parameters.

private

```
def article_params
  params.require(:article).permit(:author, :content, :all_tags)
end
```

Create the form with a text field for tags. We will use AJAX to create an article.

app/views/articles/_form.html.erb:

```rhtml
<div class="row text-center">
  <%= form_for(@article, remote: true) do |f| %>
    <div class="large-10 large-centered columns">
      <%= f.text_field :author, placeholder: "Author name" %>
    </div>
    <div class="large-10 large-centered columns">
      <%= f.text_area :content, placeholder: "Your post", rows: 5 %>
    </div>
    <div class="large-10 large-centered columns">
      <%= f.text_field :all_tags, placeholder: "Tags separated with comma" %>
    </div>
    <div class="large-10 large-centered columns">
      <%= f.submit "Post", class: "button"%>
    </div>
  <% end %>
</div>
```

The remote: true attribute must be specified to make an AJAX call to the create action in articles controller.

index.html.erb:

```rhtml
<div class="row">
  <div class="large-8 columns">
    <%= render  "form" %>
  </div>
</div>
```

routes.rb:

```ruby
Rails.application.routes.draw do
  resources :articles
  root 'articles#index'
end
```

Add css to articles.scss:

Run the rails server.

```
ActionController::RoutingError (No route matches [GET] "/javascripts/vendor/modernizr.js"):
```

Modernizr tells you what HTML, CSS and JavaScript features the user’s browser has to offer.


```ruby
gem 'modernizr-rails'
```

bundle


In layout:

```rhtml
<%= javascript_include_tag :modernizr %>
```

in the head section. Otherwise, you will have problems loading modernizr.js. Restart the server.

```
Sprockets::Rails::Helper::AssetNotPrecompiled in Articles#index
Asset was not declared to be precompiled in production.
Add `Rails.application.config.assets.precompile += %w( modernizr.js )` to `config/initializers/assets.rb` and restart your server
```

Add the above declaration and restart the server.


create.js.erb:

```rhtml
var new_post = $("<%= escape_javascript(render(partial: @article))%>").hide();
$('#articles').prepend(new_post);
$('#article_<%= @article.id %>').fadeIn('slow');
$('#new_article')[0].reset();
```



Search by Tag

Implement the method to find all articles that is tagged with a certain tag in article.rb:

```ruby
def self.tagged_with(name)
  Tag.find_by(name: name).articles
end
```

Change the index to :

```ruby
@articles = if params[:tag]
  Article.tagged_with(params[:tag])
else
  Article.all
end
```

```ruby
get 'tags/:tag', to: 'articles#index', as: 'tag'
```

Tag Cloud

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

tag_cloud helper.

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

tags.scss

```css
.css1 { font-size: 1.0em;}
.css2 { font-size: 1.2em;}
.css3 { font-size: 1.4em;}
.css4 { font-size: 1.6em;}
```

Create an article with some tags.

Change index to display the articles:

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

https://www.sitepoint.com/tagging-scratch-rails/

Resources

https://modernizr.com