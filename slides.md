# Maintainable Templates

Brendan Loudermilk *(@bloudermilk)*

Developer, philosophie

## Why are we here?

Templates are frequently neglected.

## Assumptions

You know how to write "clean" markup.

## Unmaintainable templates

* Markup repetition
* Logic in templates

## Markup Repetition

Good designers repeat themselves.

Good programmers don't.

### Avoiding markup repetition

Abstract interface components.

Use partials.

## Logic in templates

Highly repetitive.

Painful to test.

### Logic in a template

```erb
<h3>Your Saved Credit Card</h3>

<dl>
  <dt>Number</dt>
  <dd>XXXX-XXXX-XXXX-<%= @credit_card.number[-4..-1] %></dd>
  <dt>Exp. Date</dt>
  <dd>
    <%= @credit_card.expiration_month %> / <%= @credit_card.expiration_year %>
  </dd>
</dl>
```

### Repeated logic in another template

```erb
<p>
  Thanks for ordering! Your purchase has been billed to your credit card:
  <strong>XXXX-XXXX-XXXX-<%= @order.credit_card.number[-4..-1] %></strong>
</p>
```

### Other views with the same logic

...are inevitable.

## Helpers

> View Helpers live in app/helpers and provide small snippets of reusable code
for views.

<cite>[Rails Guides][helper_guide]</cite>

[helper_guide]: http://guides.rubyonrails.org/getting_started.html#view-helpers

### Defining helpers

```ruby
module CreditCardHelper
  def masked_credit_card_number(number)
    "XXXX-XXXX-XXXX-" + number[-4..-1]
  end
end
```

### Using helpers

```erb
<p>
  Thanks for ordering! Your purchase has been billed to your credit card:
  <strong><%= masked_credit_card_number(@credit_card.number) %></strong>
</p>
```

### Problems with helpers

* Big projects end up with *tons*
* Difficult to organize
* Complex logic isn't well suited for them
* Don't *feel* right

## Decorator Pattern

> [Decorators] attach additional responsibilities to an object dynamically.
Decorators provide a flexible alternative to subclassing for extending
functionality.

<cite>[Design Patterns: Elements of Reusable Object-Oriented Software][gang_of_four]</cite>

[gang_of_four]: http://www.amazon.com/Design-Patterns-Elements-Reusable-Object-Oriented/dp/0201633612

### Traits of a Decorator

* Wraps a single object
* Transparent interface
* Forwards methods to original object

In our case:

* Adds presentational logic to models without affecting the model itself

### Implementing a Decorator in Ruby

```ruby
class Decorator
  def initialize(component)
    @component = component
  end

  def method_missing(method, *arguments, &block)
    if @component.respond_to?(method)
      @component.send(method, *arguments, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, *)
    @component.respond_to?(method) || super
  end
end
```

### Credit Card Decorator

```ruby
class CreditCardDecorator < Decorator
  def masked_number
    "XXXX-XXXX-XXXX-" + number[-4..-1]
  end

  # ... other presentational methods
end
```

### Instantiating the decorator

```ruby
class CreditCardsController < ApplicationController
  def show
    @credit_card = CreditCardDecorator.new(
      current_user.credit_cards.find(params[:id])
    )
  end
end
```

### Using the decorator

```erb
<p>
  Thanks for ordering! Your purchase has been billed to your credit card:
  <strong><%= @credit_card.masked_number %></strong>
</p>
```

Mmmm, that's nice.

### When to decorate

Presentation logic that relates directly to a single instance of a model.

### Draper

Implementing basic decorators is easy, but [Draper][draper] adds a few helpful
features:

* Access to the view context
* Easily decorate collections
* Pretends to be decorated object (helpful for `form_for` and such)
* Easily decorate associations

[draper]: https://github.com/drapergem/draper

## Complex views

Unique and/or complex UI behavior will quickly outgrow helpers.

### Complex view example

```erb
<dl class="story-summary">
  <dt>Assigned to</dt>
  <dd>
    <% if @story.assigned_user == current_user %>
      You
    <% else %>
      <%= @story.assigned_user.name %>
    <% end %>
  </dd>
  <dt>Participants</dt>
  <dd><%= @story.participants.reject { |p| p == current_user }.map(&:name).join(", ") %></dd>
</dl>
```

### Presentation Model

> The essence of a Presentation Model is of a fully self-contained class that
> represents all the data and behavior of the UI window, but without any of the
> controls used to render that UI on the screen. A view then simply projects the
> state of the presentation model onto the glass.

<cite>[Martin Fowler][presentation_model]</cite>

[presentation_model]: http://martinfowler.com/eaaDev/PresentationModel.html

### Learning from JavaScript libraries

Thanks, Backbone.

### Designing a view object

```ruby
class StorySummaryView
  def initialize(template, story, current_user)
    @template = template
    @story = story
    @current_user = current_user
  end

  def assigned_user
    if @story.assigned_user == @current_user
      "You"
    else
      @story.assigned_user.name
    end
  end

  def participant_names
    participants.map(&:name).join(", ")
  end

  def to_s
    @template.render(partial: "story_summary", object: self)
  end

  private

  def participants
    @story.participants.reject { |p| p == @current_user }
  end
end
```

### Story summary template

```erb
<dl class="story-summary">
  <dt>Assigned to</dt>
  <dd><%= story_summary.assigned_user %></dd>
  <dt>Participants</dt>
  <dd><%= story_summary.participant_names %></dd>
</dl>
```

### Helpers to set up view objects

```ruby
module StoriesHelper
  def story_summary(story)
    StorySummaryView.new(self, story, current_user)
  end
end
```

In our calling view:

```erb
<%= story_summary(@story) %>
```

## Form Builders

Rails comes with View Objects.

### `form_for`

```erb
<%= form_for @user do |form| %>
  <div class="form-field">
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <div class="form-field">
    <%= form.label :email %>
    <%= form.text_field :email %>
  </div>
<% end %>
```

### Defining a custom FormBuilder

```ruby
class FancyFormBuilder < ActionView::Helpers::FormBuilder
  def fancy_text_field(attribute, options = {})
    @template.content_tag(:div, class: "form-field") do
      label(attribute) + text_field(attribute, options)
    end
  end
end
```

### Rendering the custom builder

```erb
<%= form_for @user, builder: FancyFormBuilder do |form| %>
  <%= form.fancy_text_field :name %>
  <%= form.fancy_text_field :email %>
<% end %>
```

## Other tips

* Use i18n
* Find gems to do this work for you (eg. [simple_form][simple_form],
  [table_cloth][tables])

[simple_form]: https://github.com/plataformatec/simple_form
[tables]: https://github.com/bobbytables/table_cloth

## Thanks!

Questions or Comments?
