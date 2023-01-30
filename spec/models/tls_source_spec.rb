RSpec.describe TlsSource, :type => :model do
  context 'on create' do
    let(:tls_source) { 'rancher' }
    let(:lets_encrypt_tls_source) { 'letsEncrypt' }
    let(:invalid_string) { Faker::String.random }
    let(:email_address) { Faker::Internet.email }

    it 'stores the TLS source' do
      subject.source = tls_source
      subject.save

      expect(TlsSource.load.source)
        .to eq(tls_source)
    end

    it 'stores the email address' do
      subject.email_address = email_address
      subject.save

      expect(TlsSource.load.email_address)
        .to eq(email_address)
    end

    it 'validates the TLS source' do
      subject.source = invalid_string

      expect { subject.save! }
        .to raise_error(ActiveModel::ValidationError)
    end

    context 'with lets-encrypt as source' do
      before do
        subject.source = lets_encrypt_tls_source
      end

      it 'requires an email address' do
        subject.email_address = nil

        expect { subject.save! }
          .to raise_error(ActiveModel::ValidationError)
      end

      it 'validates the email address' do
        subject.email_address = invalid_string

        expect { subject.save! }
          .to raise_error(ActiveModel::ValidationError)
      end
    end
  end
end
