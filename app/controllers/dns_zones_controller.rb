class DnsZonesController < ApplicationController
  include ZoneAuthorizable

  before_action :set_dns_zone, only: %i[show edit update destroy refresh]
  before_action :authorize_zone_access!, only: %i[show edit update destroy refresh]
  before_action :require_admin, only: %i[new create destroy]

  # GET /dns_zones or /dns_zones.json
  def index
    all_dns_zones = current_user.accessible_zones

    @dns_zones = all_dns_zones.sort_by do |zone|
      parts = zone.name.split('.')
      [parts.reverse[0], parts.reverse]
    end

    @dns_record = DnsRecord.new
  end

  # GET /dns_zones/1 or /dns_zones/1.json
  def show
    @dns_zone.ensure_default_records
    @dns_records = @dns_zone.dns_records
    @dns_record = DnsRecord.new if @dns_record.nil?
  end

  # GET /dns_zones/new
  def new
    @dns_zone = DnsZone.new
    @dns_zone.redis_host = ENV.fetch('REDIS_HOST', 'localhost')
  end

  # GET /dns_zones/1/edit
  def edit
  end

  def refresh
    @dns_zone.ensure_default_records
    @dns_zone.refresh
    redirect_to dns_zones_path
  end

  # POST /dns_zones or /dns_zones.json
  def create
    @dns_zone = DnsZone.new(dns_zone_params)

    respond_to do |format|
      if @dns_zone.save
        @dns_zone.ensure_default_records
        @dns_zone.refresh
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
  def destroy # rubocop:disable Metrics/MethodLength
    can_delete = true if @dns_zone.dns_records.count.zero?
    if can_delete
      @dns_zone.destroy!
      respond_to do |format|
        format.html { redirect_to dns_zones_url, notice: 'DNS Zone was successfully deleted.' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to dns_zones_url, alert: 'DNS Zone could not be deleted.' }
        format.json { render json: "{errors: 'Can't destroy zone with records'}", status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dns_zone
    @dns_zone = DnsZone.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def dns_zone_params
    params.require(:dns_zone).permit(:name, :redis_host, :primary_ns, :admin_email)
  end
end
