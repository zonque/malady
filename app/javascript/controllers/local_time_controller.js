import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time"]
  connect() {
    this.timeTargets.forEach((el) => {
      const utc = el.getAttribute("datetime")
      if (!utc) return
      const date = new Date(utc)
      // Metrics that ignore time render the date only (see DataPoint#ignore_time).
      el.textContent = el.dataset.dateOnly ? date.toLocaleDateString() : date.toLocaleString()
    })
  }
}
