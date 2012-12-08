class MyClassesController < ApplicationController

  def get_feed
    if session[:user_id]
      render :json => MyClasses.get_feed(session[:user_id]).to_json
    else
      render :json => {}.to_json
    end
  end

end