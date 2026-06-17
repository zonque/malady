import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time"]
  static values = { today: String, yesterday: String }

  connect() {
    this.timeTargets.forEach((el) => {
      const utc = el.getAttribute("datetime")
      if (!utc) return
      const date = new Date(utc)
      const rel = this.relativeDay(date)
      // Show the weekday alongside the date everywhere a reading's time appears.
      const dateOpts = { weekday: "short", year: "numeric", month: "numeric", day: "numeric" }
      if (el.dataset.dateOnly) {
        // Metrics that ignore time render the date only (see DataPoint#ignore_time).
        el.textContent = rel || date.toLocaleDateString([], dateOpts)
      } else {
        const time = date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
        el.textContent = rel ? `${rel} ${time}` : date.toLocaleString([], { ...dateOpts, hour: "2-digit", minute: "2-digit" })
      }
    })
  }

  // The (i18n) word for today/yesterday when the date falls within a day of now in
  // the browser's local zone, else null so callers show the absolute date.
  relativeDay(date) {
    const midnight = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate())
    const days = Math.round((midnight(new Date()) - midnight(date)) / 86_400_000)
    if (days === 0) return this.todayValue || null
    if (days === 1) return this.yesterdayValue || null
    return null
  }
}
