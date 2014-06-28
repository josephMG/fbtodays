class WelcomesController < ApplicationController
  def index
    params.permit!
    if params[:code]
        session[:access_token] = session[:oauth].get_access_token(params[:code])
    end
    begin
        @home = @graph.get_object("me")
        redirect_to fbtodays_url and return
    rescue
        return
    end
  end
end
