# Maintainable Templates

* Templates (views) often become unwieldily
* Big projects often suffer from
  * Lots of markup repetition
  * Lots of logic repitition
* Which leads to
  * Inconsistent markup throughout site
  * Inconvenient to change (for example, imagine you're asked to separate all
    user phone numbers with periods instead of dashes)

## Decorator Pattern

* Definition of pattern
* PORO implementation
* Introduction to Draper

## Using helpers to build your views

* Define helper methods for any component that is repeated more than once, for
  example `MarkupHelper#page_header`

## Removing logic from views

* Show some examples of seemingly innocuous logic found in views that, when
  moved, leads more maintainable views

## Use HAML?

* Don't personally use it, but a lot of people find its conciseness appealing

## DOM in Ruby?

* We could (should?) be using objects on the server-side to represent
  complicated views. If you find yourself dealing with a lot of logic in your
  view, try representing the the component as an object that renders itself.
