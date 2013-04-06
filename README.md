## What

Rails controller spec helpers for warden. If you're using warden
without devise in rails, due to how action controller sets up the test
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
  
  def sign_in(user)
    warden.set_user(user)
  end
end
```

## Thanks

* Devise: https://github.com/platformatec/devise
* Kentaro Imai: http://kentaroimai.com/articles/1-controller-test-helpers-for-warden
