class DnsRecordsController < ApplicationController
  before_action :set_dns_zone

  def create # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    @dns_record = @dns_zone.dns_records.new(dns_record_params)
    @dns_record.ttl = @dns_record.time_to_live
    @dns_record.record_type = DnsRecord::A

    respond_to do |format|
      if @dns_record.save
        @dns_record.add_a if @dns_record.record_type == DnsRecord::A
        format.html { redirect_to dns_zone_dns_records_path(@dns_zone), notice: 'Dns record was successfully created.' }
        format.json { render :index, status: :created, location: @dns_zone }
      else
        @dns_zone.dns_records.reload
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @dns_record.errors, status: :unprocessable_entity }
      end
    end
  end

  def index
    # @dns_records = DnsRecord.where(dns_zone_id: @dns_zone.id).order(:name)
    @dns_record = DnsRecord.new
  end

  def show
    @dns_records = @dns_zone.dns_records
  end

  def destroy
    @dns_record = @dns_zone.dns_records.find(params[:id])
    @dns_record.del_a
    @dns_record.destroy

    respond_to do |format|
      format.html { redirect_to dns_zone_dns_records_path(@dns_zone), notice: 'Dns record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_dns_zone
    @dns_zone = DnsZone.find(params[:dns_zone_id])
  end

  def dns_record_params
    params.require(:dns_record).permit(:name, :data, :ttl)
  end
end
