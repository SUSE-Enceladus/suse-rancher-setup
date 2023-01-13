module PreFlight
  class ChecksController < PreFlight::ApplicationController
    def index
      workflow.load_pre_flight_checks!
      @checks = PreFlight::Check.all

      @all_complete = PreFlight::Check.all_complete?
      @all_passed = PreFlight::Check.all_passed?
      @any_failed = @all_complete && !@all_passed
      @any_pending = PreFlight::Check.pending.count > 0
      @refresh_timer = 5 unless @all_complete

      @in_progress = @checks.not_submitted.first if !@all_complete && !@any_pending
      @in_progress&.submit!

      if @all_passed
        flash[:success] = t('engines.pre-flight.checks.all_passed')
      elsif @any_failed
        flash[:danger] = t('engines.pre-flight.checks.any_failed')
      end
    end

    def retry
      @checks = PreFlight::Check.all
      @checks.all_failed.each(&:reset!)
      redirect_to pre_flight.checks_path
    end
  end
end
