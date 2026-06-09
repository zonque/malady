import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "enumWrapper"]

  connect() { this.toggleEnum() }

  toggleEnum() {
    const isEnum = this.typeTarget.value === "enumeration"
    this.enumWrapperTarget.hidden = !isEnum
  }
}
