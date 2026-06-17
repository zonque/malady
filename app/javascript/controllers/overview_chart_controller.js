import { Controller } from "@hotwired/stimulus"

// Renders one normalized (0–100%) multi-line chart for a period section using the
// global Chart.js (loaded via Chartkick's Chart.bundle). Each line is scaled to its
// own min–max; tooltips show the real values.
export default class extends Controller {
  static values = { series: Array, period: String, today: String, yesterday: String }

  connect() {
    const Chart = window.Chart
    if (!Chart || this.seriesValue.length === 0) return

    const palette = ["#4f46e5", "#059669", "#d97706", "#dc2626", "#7c3aed", "#0891b2", "#db2777", "#65a30d"]
    const period = this.periodValue
    const fmt = (ms) => {
      const d = new Date(ms)
      if (period === "day") return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
      const rel = this.relativeDay(d)
      const time = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
      return rel ? `${rel} ${time}` : d.toLocaleString([], { weekday: "short", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })
    }

    const datasets = this.seriesValue.map((s, i) => {
      const ys = s.points.map((p) => p.y)
      const min = Math.min(...ys)
      const max = Math.max(...ys)
      const range = max - min
      const color = palette[i % palette.length]
      return {
        label: s.label,
        borderColor: color,
        backgroundColor: color,
        tension: 0.3,
        pointRadius: 2,
        data: s.points.map((p) => ({ x: p.x, y: range === 0 ? 50 : ((p.y - min) / range) * 100, actual: p.y })),
      }
    })

    this.chart = new Chart(this.element, {
      type: "line",
      data: { datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "nearest", intersect: false },
        scales: {
          x: { type: "linear", ticks: { maxTicksLimit: 6, callback: (v) => fmt(v) } },
          y: { min: 0, max: 100, ticks: { callback: (v) => v + "%" } },
        },
        plugins: {
          legend: { display: true, position: "bottom" },
          tooltip: {
            callbacks: {
              title: (items) => (items.length ? fmt(items[0].parsed.x) : ""),
              label: (ctx) => `${ctx.dataset.label}: ${ctx.raw.actual}`,
            },
          },
        },
      },
    })
  }

  // The (i18n) word for today/yesterday when the date falls within a day of now in
  // the browser's local zone, else null so the absolute date is shown.
  relativeDay(date) {
    const midnight = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate())
    const days = Math.round((midnight(new Date()) - midnight(date)) / 86_400_000)
    if (days === 0) return this.todayValue || null
    if (days === 1) return this.yesterdayValue || null
    return null
  }

  disconnect() {
    if (this.chart) { this.chart.destroy(); this.chart = null }
  }
}
