import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "enumWrapper", "defaultWrapper"]

  // Types that appear in charts and therefore support a default value.
  static CHARTABLE = ["decimal", "integer", "percentage", "boolean", "enumeration"]

  connect() {
    this.toggleEnum()
    this.toggleDefault()
  }

  toggleEnum() {
    const isEnum = this.typeTarget.value === "enumeration"
    this.enumWrapperTarget.hidden = !isEnum
  }

  toggleDefault() {
    if (!this.hasDefaultWrapperTarget) return
    const chartable = this.constructor.CHARTABLE.includes(this.typeTarget.value)
    this.defaultWrapperTarget.hidden = !chartable
  }
}
