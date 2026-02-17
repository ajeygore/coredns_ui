class ApiTokensController < ApplicationController
  before_action :set_api_token, only: %i[destroy]

  def index
    @api_tokens = if current_user.admin?
                    ApiToken.all
                  else
                    current_user.api_tokens
                  end
    @api_token = ApiToken.new
  end

  def new
    @api_token = ApiToken.new(permitted_zones: current_user.permitted_zones)
  end

  def create
    @api_token = current_user.api_tokens.new(api_token_params)

    if @api_token.save
      redirect_to api_tokens_path, notice: "API token was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @api_token.destroy!

    respond_to do |format|
      format.html { redirect_to api_tokens_url, notice: "Api token was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_api_token
    @api_token = ApiToken.find(params[:id])
  end

  def api_token_params
    params.require(:api_token).permit(:permitted_zones, :expires_at)
  end
end
