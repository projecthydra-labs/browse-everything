# frozen_string_literal: true

include BrowserConfigHelper

describe BrowseEverything::Driver::GoogleDrive, vcr: { cassette_name: 'google_drive', record: :none } do
  let(:browser) { BrowseEverything::Browser.new(url_options) }
  let(:provider) { browser.providers['google_drive'] }
  let(:provider_yml) do
    {
      client_id: 'CLIENTID', client_secret: 'CLIENTSECRET',
      url_options: { port: '3000', protocol: 'http://', host: 'example.com' }
    }
  end

  before do
    stub_configuration
  end

  after do
    unstub_configuration
  end

  describe 'simple properties' do
    subject { provider }

    its(:name)      { is_expected.to eq('Google Drive') }
    its(:key)       { is_expected.to eq('google_drive') }
    its(:icon)      { is_expected.to eq('google-plus-sign') }
  end

  describe '#validate_config' do
    it 'raises and error with an incomplete configuration' do
      expect { BrowseEverything::Driver::GoogleDrive.new({}) }.to raise_error(BrowseEverything::InitializationError)
    end

    it 'raises and error with a configuration without a client secret' do
      expect { BrowseEverything::Driver::GoogleDrive.new(client_id: 'test-client-id') }.to raise_error(BrowseEverything::InitializationError)
    end
  end

  context 'without valid credentials' do
    let(:driver) { described_class.new(provider_yml) }

    describe '#token=' do
      let(:value) { 'test' }

      it 'restores the credentials' do
        allow(driver).to receive(:restore_credentials)
        driver.token = value
        expect(driver).to have_received(:restore_credentials).with('test')
      end

      context 'when set to a Hash' do
        let(:value) { { 'access_token' => 'test' } }

        before do
          driver.token = value
        end

        it 'sets the access token value' do
          expect(driver.token).to be_a String
          expect(driver.token).to eq 'test'
        end
      end
    end
  end

  context 'with a valid connection' do
    let(:driver) { described_class.new(provider_yml) }

    before do
      driver.connect({ code: 'code' }, {})
    end

    describe '#authorized?' do
      it 'is authorized' do
        expect(driver.authorized?).to be true
      end
    end

    describe '#contents' do
      subject(:contents) { driver.contents.to_a }

      let(:drive_service_class) { class_double(Google::Apis::DriveV3::DriveService).as_stubbed_const(transfer_nested_constants: true) }
      let(:drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }
      let(:file_list) { instance_double(Google::Apis::DriveV3::FileList) }
      let(:file1) { instance_double(Google::Apis::DriveV3::File) }
      let(:file2) { instance_double(Google::Apis::DriveV3::File) }
      let(:files) { [file1, file2] }

      before do
        allow(file1).to receive(:id).and_return('asset-id2')
        allow(file2).to receive(:id).and_return('directory-id1')
        allow(file1).to receive(:name).and_return('asset-name2.pdf')
        allow(file2).to receive(:name).and_return('directory-name1')
        allow(file1).to receive(:size).and_return('891764')
        allow(file2).to receive(:size).and_return('0')
        allow(file1).to receive(:modified_time).and_return(Time.current)
        allow(file2).to receive(:modified_time).and_return(Time.current)
        allow(file1).to receive(:mime_type).and_return('application/pdf')
        allow(file2).to receive(:mime_type).and_return('application/vnd.google-apps.folder')
        allow(file_list).to receive(:files).and_return(files)
        allow(file_list).to receive(:next_page_token).and_return(nil)
        allow(drive_service).to receive(:list_files).and_yield(file_list, nil)
        allow(drive_service).to receive(:batch).and_yield(drive_service)
        allow(drive_service).to receive(:authorization=)
        allow(drive_service).to receive(:tap).and_yield(drive_service).and_return(drive_service)
        allow(drive_service_class).to receive(:new).and_return(drive_service)
      end

      it 'retrieves files' do
        expect(contents).not_to be_empty

        expect(contents.first).to be_a BrowseEverything::FileEntry
        expect(contents.first.location).to eq 'google_drive:directory-id1'
        expect(contents.first.mtime).to be_a Time
        expect(contents.first.name).to eq 'directory-name1'
        expect(contents.first.size).to eq 0
        expect(contents.first.type).to eq 'directory'

        expect(contents.last).to be_a BrowseEverything::FileEntry
        expect(contents.last.location).to eq 'google_drive:asset-id2'
        expect(contents.last.mtime).to be_a Time
        expect(contents.last.name).to eq 'asset-name2.pdf'
        expect(contents.last.size).to eq 891764
        expect(contents.last.type).to eq 'application/pdf'
      end

      context 'when an error is encountered while authenticating' do
        before do
          allow(drive_service).to receive(:list_files).and_yield(file_list, Google::Apis::Error.new('test error'))
        end

        it 'raises an exception' do
          expect { driver.contents.to_a }.to raise_error(Google::Apis::Error, 'test error')
        end
      end
    end

    describe '#link_for' do
      subject(:link) { driver.link_for('asset-id2') }

      it 'generates the link for a Google Drive asset' do
        expect(link).to be_an Array
        expect(link.first).to eq 'https://www.googleapis.com/drive/v3/files/asset-id2?alt=media'
        expect(link.last).to be_a Hash
        expect(link.last).to include auth_header: { 'Authorization' => 'Bearer access-token' }
        expect(link.last).to include :expires
        expect(link.last).to include file_name: 'asset-name2.pdf'
        expect(link.last).to include file_size: 0
      end
    end

    describe '#auth_link' do
      subject(:uri) { driver.auth_link }

      it 'exposes the authorization endpoint URI' do
        expect(uri).to be_a Addressable::URI
        expect(uri.to_s).to eq 'https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt=force&client_id=CLIENTID&include_granted_scopes=true&redirect_uri=http://example.com:3000/browse/connect&response_type=code&scope=https://www.googleapis.com/auth/drive.readonly'
      end
    end

    describe '#drive' do
      subject(:drive) { driver.drive_service }

      it 'exposes the Google Drive API client' do
        expect(drive).to be_a Google::Apis::DriveV3::DriveService
      end
    end
  end
end
