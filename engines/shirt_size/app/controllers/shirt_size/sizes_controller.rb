module ShirtSize
  class SizesController < ApplicationController
    layout 'layouts/application'

    def new;
      @size = KeyValue.get(:cluster_size, 'small')
      @sizes = form_sizes()
    end

    def create
      @size = size_param()
      KeyValue.set(:cluster_size, @size)
      render :show
    end

    private

    def form_sizes
      [
        OpenStruct.new(size: 'small', caption: 'Small'),
        OpenStruct.new(size: 'medium', caption: 'Medium'),
        OpenStruct.new(size: 'large', caption: 'Large')
      ]
    end

    def size_param
      params.require(:size)
      params[:size]
    end

  end
end
