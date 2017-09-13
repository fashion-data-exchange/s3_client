require 'aws-sdk-s3'
require "s3_client/version"

module FDE
  module S3Client

    class AWSAccessKeyIDNotDefinedError < StandardError; end
    class AWSSecretAccessKeyNotDefinedError < StandardError; end
    class AWSRegionNotDefinedError < StandardError; end
    class AWSS3BucketNameNotDefinedError < StandardError; end
    class BucketNameNotDefinedError < StandardError; end

    class Config
      attr_accessor :aws_access_key_id,
        :aws_secret_access_key,
        :aws_region,
        :bucket_name
    end

    def self.config
      @@config ||= Config.new
    end

    def self.configure
      yield self.config
    end

    def self.s3
      if self.config.aws_region.to_s.empty?
        raise AWSRegionNotDefinedError
      end
      Aws::S3::Resource.new(
        region: self.config.aws_region,
        credentials: self.credentials
      )
    end

    def self.credentials
      if self.config.aws_access_key_id.to_s.empty?
        raise AWSAccessKeyIDNotDefinedError
      end
      if self.config.aws_secret_access_key.to_s.empty?
        raise AWSSecretAccessKeyNotDefinedError
      end
      Aws::Credentials.new(
        config.aws_access_key_id,
        config.aws_secret_access_key
      )
    end

    def self.bucket
      if self.config.bucket_name.to_s.empty?
        raise BucketNameNotDefinedError
      end
      self.s3.bucket(self.config.bucket_name)
    end

    def self.upload(file_path, options = {})
      if options[:key]
        key = options[:folder].to_s + options[:key]
      else
        key = options[:folder].to_s + File.basename(file_path)
      end
      self.s3.bucket(self.config.bucket_name).object(key).upload_file(file_path)
    end

    def self.delete(key)
      object = self.bucket.object(key)
      object.delete
    end

    def self.list
      self.bucket.objects.collect(&:key)
    end

    def self.move(key, new_key)
      object = self.bucket.object(key)
      target = "#{object.bucket.name}/#{new_key}"
      object.move_to(target)
    end

    def self.download(key, target)
      object = self.bucket.object(key)
      object.download_file(target)
    end

  end
end
