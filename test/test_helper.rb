ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/skip_dsl"
require "minitest/reporters"  # for Colorized output

#  For colorful output!
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # turn on mocking
  def setup
    # when test mode enabled, all requests to omniauth will be short-circuited
    # to use the mock authentication hash
    OmniAuth.config.test_mode = true
  end
  # Add more helper methods to be used by all tests here...

  def mock_auth_hash(user, provider)
    case provider
    when :github
      return {
        provider: user.provider,
        uid: user.uid,
        info: {
          email: user.email,
          nickname: user.username
        }
      }

    when :google_oauth2
      return {
        provider: user.provider,
        uid: user.uid,
        info: {
          email: user.email,
          name: user.username
        }
      }
    end
  end

  def login(user, provider)
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(mock_auth_hash(user, provider))

    get callback_path(provider)
  end

end
