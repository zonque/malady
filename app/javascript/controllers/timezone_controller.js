import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { current: String, reload: Boolean }

  connect() {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!tz || tz === this.currentValue) return
    fetch("/timezone", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content,
      },
      body: JSON.stringify({ time_zone: tz }),
    }).then((r) => { if (r.ok && this.reloadValue) window.location.reload() })
  }
}
