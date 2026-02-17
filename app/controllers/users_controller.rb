class UsersController < ApplicationController
  before_action :require_admin

  def index
    @users = User.order(:email)
    @user = User.new(permitted_zones: '*')
  end

  def create
    @user = User.new(user_params)
    @user.permitted = true

    if @user.save
      redirect_to users_path, notice: "User #{@user.email} has been invited."
    else
      @users = User.order(:email)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @user = User.find(params[:id])

    if params[:user][:admin] == '0' && @user.id == current_user.id
      redirect_to users_path, alert: "You cannot remove your own admin privileges."
      return
    end

    if params[:user][:admin] == '0' && User.where(admin: true).count == 1 && @user.admin?
      redirect_to users_path, alert: "Cannot remove the last admin."
      return
    end

    if @user.update(user_params)
      redirect_to users_path, notice: "User #{@user.email} has been updated."
    else
      @users = User.order(:email)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])

    if @user.id == current_user.id
      redirect_to users_path, alert: "You cannot delete yourself."
      return
    end

    @user.destroy
    redirect_to users_path, notice: "User #{@user.email} has been removed."
  end

  private

  def user_params
    params.require(:user).permit(:email, :permitted_zones, :admin)
  end
end
