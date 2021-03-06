require 'database_cleaner'

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    # Before the test suites runs make sure the database is empty
    DatabaseCleaner.clean_with(:truncation)
    # and is seeded
    load "#{Rails.root}/db/seeds.rb"
  end

  config.before(:each) do |example|
    # For feature test we use truncation instead of transactions
    # because the test suite and the capybara driver do not use
    # the same server thread.
    if example.metadata[:type] == :feature
      # omit truncating what we have set up in db/seeds.rb
      DatabaseCleaner.strategy = :truncation, {:except => %w(roles roles_static_permissions static_permissions configurations architectures)}
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
