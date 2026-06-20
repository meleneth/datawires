import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 0 },
    remove: { type: Boolean, default: true }
  }

  connect() {
    if (this.durationValue > 0) {
      this.timeout = window.setTimeout(() => this.dismiss(), this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) window.clearTimeout(this.timeout)
  }

  dismiss(event) {
    if (event) event.preventDefault()

    this.element.dataset.state = "closed"

    window.setTimeout(() => {
      if (this.removeValue) {
        this.element.remove()
      } else {
        this.element.hidden = true
      }
    }, 200)
  }
}
