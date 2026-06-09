import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time"]
  connect() {
    this.timeTargets.forEach((el) => {
      const utc = el.getAttribute("datetime")
      if (utc) el.textContent = new Date(utc).toLocaleString()
    })
  }
}
