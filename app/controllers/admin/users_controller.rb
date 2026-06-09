class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :destroy, :lock, :unlock, :confirm]

  def index
    @users = User.order(:email)
  end

  def show; end

  def destroy
    raise ActiveRecord::RecordNotFound if @user == current_user # no self-deletion (lockout guard)
    @user.destroy
    redirect_to admin_users_path, notice: t(".deleted")
  end

  def lock
    raise ActiveRecord::RecordNotFound if @user == current_user # no self-lock (lockout guard)
    @user.lock_access!
    redirect_back fallback_location: admin_users_path, notice: t(".locked")
  end

  def unlock
    @user.unlock_access!
    redirect_back fallback_location: admin_users_path, notice: t(".unlocked")
  end

  def confirm
    @user.confirm
    redirect_back fallback_location: admin_users_path, notice: t(".confirmed")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
