import { Controller } from "@hotwired/stimulus"
import { ICON_NAMES } from "bootstrap_icons"

// Inline searchable Bootstrap Icons picker.
//
// Markup contract:
//   - input  (hidden field, metric[icon])  -> data-icon-picker-target="input"
//   - input  (search box)                  -> data-icon-picker-target="search"
//   - scrollable element for the grid      -> data-icon-picker-target="grid"
//     (with data-action="scroll->icon-picker#scroll")
//   - element previewing the selection     -> data-icon-picker-target="preview"
//   - element showing the rendered/total   -> data-icon-picker-target="count"  (optional)
//
// All ~2000 icons are reachable: matches render in batches as the grid scrolls,
// so the full set is browsable without a search while keeping each keystroke cheap.
export default class extends Controller {
  static targets = ["input", "search", "grid", "preview", "count"]
  static values = { batch: { type: Number, default: 200 } }

  connect() {
    this.applyFilter(this.hasSearchTarget ? this.searchTarget.value : "")
    this.reflectSelection(this.inputTarget.value)
  }

  filter() {
    this.applyFilter(this.searchTarget.value)
  }

  // Recompute matches for the query and render the first batch from the top.
  applyFilter(query) {
    const q = query.trim().toLowerCase()
    this.matches = q ? ICON_NAMES.filter((n) => n.includes(q)) : ICON_NAMES
    this.rendered = 0
    this.gridTarget.replaceChildren()
    this.gridTarget.scrollTop = 0
    this.renderMore()
  }

  // Append the next batch of icon buttons.
  renderMore() {
    const next = this.matches.slice(this.rendered, this.rendered + this.batchValue)
    const selected = this.inputTarget.value
    this.gridTarget.append(...next.map((name) => this.button(name, name === selected)))
    this.rendered += next.length
    this.updateCount()
  }

  // Lazy-load the next batch as the grid nears its bottom.
  scroll() {
    if (this.rendered >= this.matches.length) return
    const el = this.gridTarget
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 80) this.renderMore()
  }

  button(name, active) {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.title = name
    btn.dataset.action = "icon-picker#select"
    btn.dataset.name = name
    btn.setAttribute("aria-label", name)

    const icon = document.createElement("i")
    icon.className = `bi bi-${name}`
    icon.setAttribute("aria-hidden", "true")
    btn.appendChild(icon)

    this.styleButton(btn, active)
    return btn
  }

  styleButton(btn, active) {
    btn.className =
      "flex items-center justify-center rounded-lg border p-2 text-xl transition " +
      (active
        ? "border-indigo-500 bg-indigo-50 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-300"
        : "border-gray-200 hover:border-indigo-300 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800")
  }

  select(event) {
    const name = event.currentTarget.dataset.name
    this.inputTarget.value = name
    this.reflectSelection(name)
    this.markActive(name) // restyle in place — keeps scroll position
  }

  clear() {
    this.inputTarget.value = ""
    this.reflectSelection("")
    this.markActive(null)
  }

  // Re-apply the active highlight to the currently rendered buttons.
  markActive(name) {
    this.gridTarget.querySelectorAll("button[data-name]").forEach((btn) => {
      this.styleButton(btn, btn.dataset.name === name)
    })
  }

  updateCount() {
    if (!this.hasCountTarget) return
    const total = this.matches.length
    this.countTarget.textContent =
      this.rendered < total ? `${this.rendered} / ${total}` : `${total}`
  }

  // Update the preview swatch.
  reflectSelection(name) {
    if (!this.hasPreviewTarget) return
    this.previewTarget.className = name
      ? `bi bi-${name} text-2xl`
      : "bi bi-question-square text-2xl text-gray-300 dark:text-gray-600"
  }
}
