class NotificationsController < ApplicationController
  def index
    @notifications = Notification.all
  end

  def create
    Notification.find_or_create_by(notification_params)
    head :ok
  end

  def destroy
    Notification.find(params[:id]).destroy
    redirect_to notifications_path
  end

  private

  def notification_params
    params.permit(:email, :subject, :query)
  end
end
