import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.maxPoints = 30
    this.rxData = []
    this.txData = []
    this.labels = []
    this.prevStats = null
    this.initChart()
    this.poll()
    this.interval = setInterval(() => this.poll(), 2000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
    if (this.chart) this.chart.destroy()
  }

  initChart() {
    const ctx = this.canvasTarget.getContext("2d")

    for (let i = 0; i < this.maxPoints; i++) {
      this.rxData.push(0)
      this.txData.push(0)
      this.labels.push("")
    }

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labels,
        datasets: [
          {
            label: "RX",
            data: this.rxData,
            borderColor: "#00cfff",
            backgroundColor: "rgba(0, 207, 255, 0.08)",
            borderWidth: 2,
            pointRadius: 0,
            tension: 0.3,
            fill: true
          },
          {
            label: "TX",
            data: this.txData,
            borderColor: "#39ff14",
            backgroundColor: "rgba(57, 255, 20, 0.08)",
            borderWidth: 2,
            pointRadius: 0,
            tension: 0.3,
            fill: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        plugins: {
          legend: {
            labels: {
              color: "#94a3b8",
              font: { size: 11 },
              boxWidth: 12,
              padding: 8
            }
          },
          tooltip: {
            callbacks: {
              label: (ctx) => `${ctx.dataset.label}: ${this.formatBytes(ctx.raw)}/s`
            }
          }
        },
        scales: {
          x: { display: false },
          y: {
            beginAtZero: true,
            grid: { color: "rgba(148, 163, 184, 0.1)" },
            ticks: {
              color: "#94a3b8",
              font: { size: 10 },
              callback: (v) => this.formatBytes(v) + "/s",
              maxTicksLimit: 4
            }
          }
        }
      }
    })
  }

  async poll() {
    try {
      const resp = await fetch("/network_stats.json")
      const data = await resp.json()

      if (data.error || !data.interfaces) return

      let totalRx = 0, totalTx = 0
      for (const iface of Object.values(data.interfaces)) {
        totalRx += iface.rx_bytes
        totalTx += iface.tx_bytes
      }

      if (this.prevStats) {
        const dt = (data.timestamp - this.prevStats.timestamp) || 1
        const rxRate = (totalRx - this.prevStats.rx) / dt
        const txRate = (totalTx - this.prevStats.tx) / dt

        this.rxData.push(Math.max(0, rxRate))
        this.txData.push(Math.max(0, txRate))
        this.labels.push("")

        if (this.rxData.length > this.maxPoints) {
          this.rxData.shift()
          this.txData.shift()
          this.labels.shift()
        }

        this.chart.update()
      }

      this.prevStats = { rx: totalRx, tx: totalTx, timestamp: data.timestamp }
    } catch (e) {
      // silently retry on next poll
    }
  }

  formatBytes(bytes) {
    if (bytes === 0) return "0 B"
    const k = 1024
    const sizes = ["B", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(Math.abs(bytes)) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
  }
}
