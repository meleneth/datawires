import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  open() {
    this.panelTarget.hidden = false
  }

  close() {
    this.panelTarget.hidden = true
  }

  backdropClose(event) {
    if (event.target === this.panelTarget) this.close()
  }
}
