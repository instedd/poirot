class PagesController < ApplicationController
  def index
    redirect_to '/log_entries'
  end
end
