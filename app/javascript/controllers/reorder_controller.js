import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "handle"]

  connect() {
    this.handleTargets.forEach((h) => {
      h.addEventListener("dragstart", (e) => this.start(e, h))
      h.addEventListener("dragend", () => this.end())
    })
    this.itemTargets.forEach((el) => {
      el.addEventListener("dragover", (e) => this.over(e, el))
    })
  }

  start(e, handle) {
    this.dragging = handle.closest("[data-reorder-target='item']")
    this.dragging.classList.add("opacity-50")
    if (e.dataTransfer) e.dataTransfer.effectAllowed = "move"
  }

  over(e, el) {
    e.preventDefault()
    if (!this.dragging || el === this.dragging) return
    const items = this.itemTargets
    const from = items.indexOf(this.dragging)
    const to = items.indexOf(el)
    if (from < to) { el.after(this.dragging) } else { el.before(this.dragging) }
  }

  end() {
    if (this.dragging) this.dragging.classList.remove("opacity-50")
    this.dragging = null
    this.save()
  }

  save() {
    const order = this.itemTargets.map((el) => el.dataset.id)
    fetch("/metrics/positions", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content,
      },
      body: JSON.stringify({ order }),
    })
  }
}
