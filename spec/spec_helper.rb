require 'dotenv'
Dotenv.load('spec/fixtures/test.env')

require 'bundler/setup'
require 'vcr'
require 'pry'
require 's3_client'


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassetts"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = {
    match_requests_on: [:method, :path]
  }
end

FDE::S3Client.configure do |config|
  config.aws_access_key_id = ENV.fetch("AWS_ACCESS_KEY_ID")
  config.aws_secret_access_key = ENV.fetch("AWS_SECRET_ACCESS_KEY")
  config.aws_region = ENV.fetch("AWS_REGION")
  config.bucket_name = ENV.fetch("S3_BUCKET_NAME")
end

