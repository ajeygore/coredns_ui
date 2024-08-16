class DnsZonesController < ApplicationController
  before_action :set_dns_zone, only: %i[show edit update destroy refresh]

  # GET /dns_zones or /dns_zones.json
  def index
    @dns_zones = DnsZone.all
    @dns_record = DnsRecord.new
  end

  # GET /dns_zones/1 or /dns_zones/1.json
  def show
    @dns_records = @dns_zone.dns_records
    @dns_record = DnsRecord.new if @dns_record.nil?
  end

  # GET /dns_zones/new
  def new
    @dns_zone = DnsZone.new
    @dns_zone.redis_host = "127.0.0.1"
  end

  # GET /dns_zones/1/edit
  def edit
  end

  def refresh
    @dns_zone.refresh
    redirect_to dns_zones_path
  end

  # POST /dns_zones or /dns_zones.json
  def create
    @dns_zone = DnsZone.new(dns_zone_params)

    respond_to do |format|
      if @dns_zone.save
        format.html { redirect_to dns_zones_path, notice: "Dns zone was successfully created." }
        format.json { render :index, status: :created, location: @dns_zone }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dns_zone.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dns_zones/1 or /dns_zones/1.json
  def update
    respond_to do |format|
      if @dns_zone.update(dns_zone_params)
        format.html { redirect_to dns_zone_url(@dns_zone), notice: "Dns zone was successfully updated." }
        format.json { render :show, status: :ok, location: @dns_zone }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dns_zone.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dns_zones/1 or /dns_zones/1.json
  def destroy
    @dns_zone.destroy!
    respond_to do |format|
      format.html { redirect_to dns_zones_url, notice: "Dns zone was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dns_zone
    @dns_zone = DnsZone.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def dns_zone_params
    params.require(:dns_zone).permit(:name, :redis_host)
  end
end
