## What

Rails controller spec helpers for Warden. If you're using Warden
without Devise in rails, due to how ActionController sets up the test
environment, custom test setup code is necessary.

## Usage

```ruby
# Gemfile
group :test do
  gem 'warden-rspec-rails'
end

# spec_helper.rb
RSpec.configure do |c|
  c.include Warden::Test::ControllerHelpers, type: :controller
end
```

This will define helper methods in controller tests that you can use to manage
authentication, such as:
- `warden`: Access the `Warden::Proxy`.
- `login_as`: Same as the `Warden::Test::Helpers` `login_as` method.
- `logout`: Same as the `Warden::Test::Helpers` `logout` method.
- `unlogin`: Removes the user(s) from the logged-in list, but leaves the
    session value so the user can be fetched on access.

## Thanks

* Devise: https://github.com/platformatec/devise
* Kentaro Imai: http://kentaroimai.com/articles/1-controller-test-helpers-for-warden
