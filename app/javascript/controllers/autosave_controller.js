import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 400 }
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    this.clearTimer()
  }

  queue(event) {
    event?.preventDefault()
    this.clearTimer()
    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  submit(event) {
    event?.preventDefault()
    this.clearTimer()
    this.element.requestSubmit()
  }

  clearTimer() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}
