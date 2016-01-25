class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def create
    new_user_params = user_params
    new_user_params[:password] = SecureRandom.base64
    User.create!(new_user_params)
    redirect_to :users
  end

  def destroy
    user = User.find(params[:id])
    user.destroy!
    redirect_to :users
  end

  private

  def user_params
    params.require(:user).permit(:email)
  end
end
