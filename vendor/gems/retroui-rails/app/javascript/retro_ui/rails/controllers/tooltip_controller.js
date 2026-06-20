import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  show() {
    this.contentTarget.hidden = false
  }

  hide() {
    this.contentTarget.hidden = true
  }
}
