class SessionsController < ApplicationController
  def login_form
  end

  def login
    username = params[:username]
    if username and user = User.find_by(username: username)
      session[:user_id] = user.id
      flash[:status] = :success
      flash[:result_text] = "Successfully logged in as existing user #{user.username}"
    else
      user = User.new(username: username)
      if user.save
        session[:user_id] = user.id
        flash[:status] = :success
        flash[:result_text] = "Successfully created new user #{user.username} with ID #{user.id}"
      else
        flash.now[:status] = :failure
        flash.now[:result_text] = "Could not log in"
        flash.now[:messages] = user.errors.messages
        render "login_form", status: :bad_request
        return
      end
    end
    redirect_to root_path
  end

  def logout
    session[:user_id] = nil
    flash[:status] = :success
    flash[:result_text] = "Successfully logged out"
    redirect_to root_path
  end

  def create
    auth_hash = request.env['omniauth.auth']
    #ap auth_hash

    @user = User.find_by(uid: auth_hash['uid'], provider: auth_hash['provider'])

    if @user
      session[:user_id] = @user.id
      flash[:success] = "#{@user.username} is logged in"
    else

    provider = auth_hash['provider']

      case provider
      when "github"
        @user = User.new uid: auth_hash['uid'], provider: auth_hash['provider'], username: auth_hash['info']['nickname'], email: auth_hash['info']['email']
        
      when "google_oauth2"
        @user = User.new uid: auth_hash['uid'], provider: auth_hash['provider'], username: auth_hash['info']['name'], email: auth_hash['info']['email']
      end
      # @user = User.new uid: auth_hash['uid'], provider: auth_hash['provider'], username: auth_hash['info']['nickname'], email: auth_hash['info']['email']

      # only reason this wouldn't work is if omni auth didn't give a provider or db was down
      if @user.save
        session[:user_id] = @user.id
        flash[:success] = "Welcome #{@user.username}"
      else
        flash[:error] = "Unable to save user!"
      end
    end

    redirect_to root_path
  end
end
