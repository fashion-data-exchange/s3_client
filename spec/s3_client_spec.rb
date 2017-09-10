require "spec_helper"

RSpec.describe FDE::S3Client do
  it "has a version number" do
    expect(FDE::S3Client::VERSION).not_to be nil
  end

  describe 'configuration' do
    it 'is of Type FDE::S3Client::Config' do
      expect(subject.config).to be_a(FDE::S3Client::Config)
    end

    it 'yields the config block' do
      expect do |b|
        subject.configure(&b)
      end.to yield_with_args
    end
  end

  describe 'credentials' do
    context 'with valid configs' do
      before do
        subject.config.aws_access_key_id = "ABCD"
        subject.config.aws_secret_access_key = "123456789"
      end

      it 'should hold an aws credential object' do
        expect(subject.credentials).to be_a(Aws::Credentials)
      end
    end

    context 'without valid configs' do
      it 'should raise an error if the aws access key is not given' do
        subject.config.aws_access_key_id = ""
        expect{ subject.credentials }.to raise_error(
          FDE::S3Client::AWSAccessKeyIDNotDefinedError
        )
      end
      it 'should raise an error if the aws secret access key is not given' do
        subject.config.aws_access_key_id = "ABCD"
        subject.config.aws_secret_access_key = ""
        expect{ subject.credentials }.to raise_error(
          FDE::S3Client::AWSSecretAccessKeyNotDefinedError
        )
      end
    end
  end

  describe 's3' do
    context 'with valid configs' do
      before do
        subject.config.aws_access_key_id = "ABCD"
        subject.config.aws_secret_access_key = "123456789"
        subject.config.aws_region = "eu"
      end

      it 'should hold an aws s3 resource' do
        expect(subject.s3).to be_a(Aws::S3::Resource)
      end
    end

    context 'without valid configs' do
      before do
        subject.config.aws_access_key_id = "ABCD"
        subject.config.aws_secret_access_key = "123456789"
        subject.config.aws_region = ""
      end

      it 'should raise an error if the aws region is not given' do
        expect{ subject.s3 }.to raise_error(
          FDE::S3Client::AWSRegionNotDefinedError
        )
      end
    end
  end

  describe 'bucket' do
    context 'with valid configs' do
      before do
        subject.config.aws_region = 'eu'
        subject.config.bucket_name = 'bucket_name'
      end

      it 'should hold an aws bucket' do
        expect(subject.bucket).to be_a(Aws::S3::Bucket)
      end
    end


    context 'without valid configs' do
      before do
        subject.config.bucket_name = ''
      end

      it 'should raise an error if the bucket name is not given' do
        expect{ subject.bucket }.to raise_error(
          FDE::S3Client::BucketNameNotDefinedError
        )
      end
    end
  end

  context 'file manipulations', :vcr do
    let(:file_name) { 'test_file.txt' }
    let(:file_path) { "spec/fixtures/#{file_name}" }

    before do
      subject.config.aws_access_key_id = ENV.fetch("AWS_ACCESS_KEY_ID")
      subject.config.aws_secret_access_key = ENV.fetch("AWS_SECRET_ACCESS_KEY")
      subject.config.aws_region = ENV.fetch("AWS_REGION")
      subject.config.bucket_name = ENV.fetch("S3_BUCKET_NAME")
    end

    describe 'upload' do
      let(:new_file_name) { 'new_test_file.txt' }
      let(:folder_name) { 'folder/' }

      it 'should upload a file to the bucket' do
        expect {
          subject.upload(file_path)
        }.to_not raise_error
      end

      it 'should upload a file to a folder' do
        expect {
          subject.upload(file_path, folder: folder_name)
        }.to_not raise_error
        expect(subject.list).to include("#{folder_name}#{file_name}")
      end

      it 'can set new key' do
        expect {
          subject.upload(file_path, key: new_file_name)
        }.to_not raise_error
        expect(subject.list).to include(new_file_name)
      end

      it 'can set new key upload it to folder' do
        expect {
          subject.upload(file_path, key: new_file_name, folder: folder_name)
        }.to_not raise_error
        expect(subject.list).to include("#{folder_name}#{file_name}")
      end
    end

    describe 'list' do
      it 'should list the all the files in the bucket' do
        subject.upload(file_path)
        expect(subject.list).to include(file_name)
      end
    end

    describe 'delete' do
      before :each do
        subject.upload(file_path)
      end

      it 'should delete a file in the bucket' do
        expect {
          subject.delete(file_name)
        }.to_not raise_error
      end

      it 'should not have the deleted file in the bucket' do
        subject.delete(file_name)
        expect(subject.list).not_to include(file_name)
      end
    end

    describe 'move' do
      let(:folder_name) { 'done/' }

      before :each do
        subject.upload(file_path)
      end

      it 'should move the a file into a folder' do
        expect {
          subject.upload(file_path)
          subject.move(file_name, "#{folder_name}#{file_name}")
        }.not_to raise_error
      end

      it 'should list the file in the folder' do
        subject.move(file_name, "#{folder_name}#{file_name}")
        expect(subject.list).to include("#{folder_name}#{file_name}")
      end
    end

    describe 'rename' do
      let(:new_file_name) { 'new.txt' }

      before :each do
        subject.upload(file_path)
      end

      it 'renames a file do' do
        expect {
          subject.move(file_name, new_file_name)
        }.not_to raise_error
      end
    end

    describe 'download' do
      let(:path) { './spec/tmp/' }

      before :each do
        subject.upload(file_path)
      end

      after :each do
        File.delete("#{path}#{file_name}")
      end

      it 'downloads a file' do
        expect {
          subject.download(file_name, "#{path}#{file_name}")
        }.to_not raise_error
        expect(File).to exist("#{path}#{file_name}")
      end
    end

  end
end
