require "bundler"
Bundler.require

run Slyde::App.new("slides.md")
