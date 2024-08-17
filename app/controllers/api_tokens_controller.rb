class ApiTokensController < ApplicationController
  before_action :set_api_token, only: %i[show edit update destroy]

  # GET /api_tokens or /api_tokens.json
  def index
    @api_tokens = ApiToken.all
    @api_token = ApiToken.new
  end

  # GET /api_tokens/1 or /api_tokens/1.json
  def show
  end

  # GET /api_tokens/new
  def new
    @api_token = ApiToken.new(user: current_user)
    @api_token.generate_token

    @api_token.save!
    redirect_to api_tokens_path
  end

  # GET /api_tokens/1/edit
  def edit
  end

  # POST /api_tokens or /api_tokens.json
  def create
    @api_token = ApiToken.new(api_token_params)

    respond_to do |format|
      if @api_token.save
        format.html { redirect_to api_token_url(@api_token), notice: "Api token was successfully created." }
        format.json { render :show, status: :created, location: @api_token }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @api_token.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_tokens/1 or /api_tokens/1.json
  def update
    respond_to do |format|
      if @api_token.update(api_token_params)
        format.html { redirect_to api_token_url(@api_token), notice: "Api token was successfully updated." }
        format.json { render :show, status: :ok, location: @api_token }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @api_token.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_tokens/1 or /api_tokens/1.json
  def destroy
    @api_token.destroy!

    respond_to do |format|
      format.html { redirect_to api_tokens_url, notice: "Api token was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_api_token
    @api_token = ApiToken.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def api_token_params
    params.require(:api_token).permit(:token, :user_id, :expires_at)
  end
end
