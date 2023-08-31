class HomeController < ApplicationController
  def index
    a = system('ffmpeg -version')
    render json: {message: a}, status: :ok
  end
end
