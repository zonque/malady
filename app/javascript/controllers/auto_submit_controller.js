import { Controller } from "@hotwired/stimulus"

// Submits this form whenever one of its controls changes — used for filter
// checkboxes / selects that update results immediately. Replaces inline
// `onchange="this.form.requestSubmit()"` so the page needs no inline scripts
// (and works under a strict Content-Security-Policy).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
