module ShirtSize
  class SizesController < ApplicationController
    def edit
      @size = KeyValue.get(:cluster_size, 'small')
      @sizes = self.form_sizes
    end

    def update
      @size = self.size_param
      KeyValue.set(:cluster_size, @size)
      render :show
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
