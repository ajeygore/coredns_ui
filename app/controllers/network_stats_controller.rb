class NetworkStatsController < ApplicationController
  def show
    stats = read_network_stats
    render json: stats
  end

  private

  def read_network_stats
    return fallback_stats unless File.exist?("/proc/net/dev")

    lines = File.readlines("/proc/net/dev").drop(2)
    result = {}

    lines.each do |line|
      parts = line.strip.split(/[\s:]+/)
      iface = parts[0]
      next if iface == "lo"

      result[iface] = {
        rx_bytes: parts[1].to_i,
        tx_bytes: parts[9].to_i
      }
    end

    { interfaces: result, timestamp: Time.now.to_f }
  end

  def fallback_stats
    { interfaces: {}, timestamp: Time.now.to_f, error: "Network stats not available on this platform" }
  end
end
