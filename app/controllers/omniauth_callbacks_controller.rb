class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_guisso_cookie
  skip_before_action :authenticate_user!

  def instedd
    auth = env['omniauth.auth']
    email = auth.info['email']
    puts email
    account = User.find_by_email(email)

    if account
      sign_in account
      next_url = env['omniauth.origin'] || root_path
      next_url = root_path if next_url == new_user_session_url
      redirect_to next_url
    else
      render :access_denied
      # redirect_to root_path
    end
  end
end
