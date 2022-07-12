module AWS
  class Permissions
    include ActiveModel::Model

    attr_accessor(:source_policy_file, :arn)

    def source_policy
      @source_policy ||= JSON.parse(File.read(@source_policy_file))
    end

    def required_actions
      self.source_policy['Statement'][0]['Action']
    end

    def generate_report
      @cli ||= AWS::Cli.load
      @report = JSON.parse(@cli.simulate_principal_policy(@arn, *self.required_actions))['EvaluationResults']
    end

    def passed?
      @report ||= self.generate_report()
      @report.all? { |result| result['EvalDecision'] == 'allowed' }
    end

    def missing_permissions()
      @report ||= self.generate_report()
      @report.map{ |result| result['EvalActionName'] if result['EvalDecision'] != 'allowed' }.compact
    end
  end
end
