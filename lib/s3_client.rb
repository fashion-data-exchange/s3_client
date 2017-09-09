require 'aws-sdk'
require "s3_client/version"

module FDE
  module S3Client

    @s3 = Aws::S3::Resource.new
    @bucket = @s3.bucket(@config[:bucket_name])

    @config = {
      bucket_name: nil,
      aws_region: nil
    }

    @valid_config_keys = @config.keys

    def self.configure(options = {})
      options.each do |key, value|
        if @valid_config_keys.include? key.to_sym
          @config[key.to_sym] = value
        end
      end
    end

    def self.config
      @config
    end

    def self.upload(file_name)
      key = File.basename(file_name)
      @s3.buckets[@config[:bucket_name]].objects[key].write(:file => file_name)
    end

    def self.delete(key)
      object = @bucket.object(key)
      object.delete
    end

    def self.list
      bucket.objects
    end

    def self.move(key, target)
      object = @bucket.object(key)
      object.move_to(target)
    end
  end
end
