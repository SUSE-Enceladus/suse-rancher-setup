module ShirtSize
  class SizesController < ShirtSize::ApplicationController
    def edit
      @size = KeyValue.get(:cluster_size, 'small')
      @sizes = self.form_sizes
    end

    def update
      @size = self.size_param
      if KeyValue.set(:cluster_size, @size)
        flash[:success] = t('engines.shirt_size.sizes.using', size: @size)
        redirect_to(helpers.next_step_path(shirt_size.edit_size_path))
      else
        flash[:warning] = t('engines.shirt_size.sizes.failed')
        redirect_to(shirt_size.edit_size_path)
      end
    end

    private

    def form_sizes
      %w(small medium large)
    end

    def size_param
      params.permit(:size)[:size]
    end
  end
end
