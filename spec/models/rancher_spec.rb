return unless defined?(Helm::Engine)

RSpec.describe Helm::Rancher, :type => :model do
  let(:mock_fqdn) { 'rancher.example.com' }
  let(:expected_namespace) { 'cattle-system' }
  let(:expected_repo_name) { 'rancher-stable' }
  let(:expected_repo_url) { 'https://releases.rancher.com/server-charts/stable' }
  let(:expected_release_name) { 'rancher-stable' }
  let(:expected_chart) { 'rancher-stable/rancher' }

  context 'on create' do
    before do
      # don't actually execute anything
      allow(Cheetah).to receive(:run).and_return(true)

      # mock out things we're not testing
      subject.fqdn = mock_fqdn
      allow(subject).to receive(:refresh)

      @mock_kubectl = double
      subject.instance_variable_set(:@kubectl, @mock_kubectl)
      # create the namespace via kubectl
      allow(@mock_kubectl)
        .to receive(:create_namespace).with(expected_namespace)
        .and_return(true)

      @mock_helm = double
      subject.instance_variable_set(:@helm, @mock_helm)
      # add the helm repo
      allow(@mock_helm)
        .to receive(:add_repo).with(expected_repo_name, expected_repo_url)
        .and_return(true)
    end

    it 'delegates the expected calls' do
      # install rancher via helm
      expect(@mock_helm)
        .to receive(:install)
        .with(
          expected_release_name,
          expected_chart,
          expected_namespace,
          [
            '--set',
            'extraEnv[0].name=CATTLE_PROMETHEUS_METRICS',
            '--set-string',
            'extraEnv[0].value=true',
            '--set',
            "hostname=#{mock_fqdn}",
            '--set',
            'replicas=3'
          ]
        ).and_return(true)

      # do it already
      subject.save!
    end

    context 'with a version number' do
      let(:expected_version) { '2.6.6' }

      before do
        subject.version = expected_version
      end

      it 'delegates the expected calls' do
        # install rancher via helm
        expect(@mock_helm)
          .to receive(:install)
          .with(
            expected_release_name,
            expected_chart,
            expected_namespace,
            [
              '--set',
              'extraEnv[0].name=CATTLE_PROMETHEUS_METRICS',
              '--set-string',
              'extraEnv[0].value=true',
              '--set',
              "hostname=#{mock_fqdn}",
              '--set',
              'replicas=3',
              '--version',
              expected_version
            ]
          ).and_return(true)

        # do it already
        subject.save!
      end
    end

    context 'with a TLS source' do
      let(:valid_tls_source) { 'rancher' }
      let(:invalid_tls_source) { 'foo' }
      let(:lets_encrypt_tls_source) { 'letsEncrypt' }

      it 'accepts a valid TLS source' do
        # install rancher via helm
        expect(@mock_helm)
          .to receive(:install)
          .with(
            expected_release_name,
            expected_chart,
            expected_namespace,
            [
              '--set',
              'extraEnv[0].name=CATTLE_PROMETHEUS_METRICS',
              '--set-string',
              'extraEnv[0].value=true',
              '--set',
              "hostname=#{mock_fqdn}",
              '--set',
              'replicas=3',
              '--set',
              "ingress.tls.source=#{valid_tls_source}"
            ]
          ).and_return(true)

        # do it already
        subject.tls_source = valid_tls_source
        subject.save!
      end

      it 'rejects an invalid TLS source' do
        subject.tls_source = invalid_tls_source
        expect { subject.save! }
          .to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Tls source '#{invalid_tls_source}' is not valid."
          )
      end

      context 'lets-encrypt' do
        let(:mock_email_address) { 'nobody@nowhere.net' }

        before do
          subject.tls_source = lets_encrypt_tls_source
        end

        it 'accepts an email address' do
          # install rancher via helm
          expect(@mock_helm)
            .to receive(:install)
            .with(
              expected_release_name,
              expected_chart,
              expected_namespace,
              [
                '--set',
                'extraEnv[0].name=CATTLE_PROMETHEUS_METRICS',
                '--set-string',
                'extraEnv[0].value=true',
                '--set',
                "hostname=#{mock_fqdn}",
                '--set',
                'replicas=3',
                '--set',
                "ingress.tls.source=#{lets_encrypt_tls_source}",
                '--set',
                "letsEncrypt.email=#{mock_email_address}"
              ]
            ).and_return(true)

          subject.email_address = mock_email_address
          subject.save!
        end

        it 'rejects a missing email for lets-encrypt' do
          expect {subject.save! }
            .to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Email address can't be blank, Email address is invalid"
            )
        end
      end
    end
  end

  context 'internal functions' do
    before do
      subject.id = expected_release_name

      @mock_kubectl = double
      subject.instance_variable_set(:@kubectl, @mock_kubectl)

      @mock_helm = double
      subject.instance_variable_set(:@helm, @mock_helm)
    end

    it 'gets the expected helm status as describe_resource' do
      expect(@mock_helm)
        .to receive(:status).with(expected_release_name, expected_namespace)
        .and_return(true)

      subject.send(:describe_resource)
    end

    it 'gets the expected kubectl status as state_attribute' do
      expect(@mock_kubectl)
        .to receive(:status).with(expected_release_name, expected_namespace)
        .and_return(true)

      subject.send(:state_attribute)
    end
  end
end
