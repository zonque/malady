import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time"]
  connect() {
    this.timeTargets.forEach((el) => {
      const utc = el.getAttribute("datetime")
      if (!utc) return
      const date = new Date(utc)
      // Show the weekday alongside the date everywhere a reading's time appears.
      const dateOpts = { weekday: "short", year: "numeric", month: "numeric", day: "numeric" }
      // Metrics that ignore time render the date only (see DataPoint#ignore_time).
      el.textContent = el.dataset.dateOnly
        ? date.toLocaleDateString([], dateOpts)
        : date.toLocaleString([], { ...dateOpts, hour: "2-digit", minute: "2-digit" })
    })
  }
}
