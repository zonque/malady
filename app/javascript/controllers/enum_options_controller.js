import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  add() {
    const input = document.createElement("input")
    input.name = "metric[enum_options][]"
    input.className = "form-input mb-2"
    this.listTarget.appendChild(input)
  }
}
