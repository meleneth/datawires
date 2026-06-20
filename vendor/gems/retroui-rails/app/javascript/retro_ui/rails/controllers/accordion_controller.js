import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]
  static values = { multiple: { type: Boolean, default: false } }

  toggle(event) {
    const trigger = event.currentTarget
    const index = this.triggerTargets.indexOf(trigger)
    const content = this.contentTargets[index]
    const opening = trigger.getAttribute("aria-expanded") !== "true"

    if (!this.multipleValue) this.closeAll()
    this.setOpen(trigger, content, opening)
  }

  closeAll() {
    this.triggerTargets.forEach((trigger, index) => {
      this.setOpen(trigger, this.contentTargets[index], false)
    })
  }

  setOpen(trigger, content, open) {
    trigger.setAttribute("aria-expanded", open ? "true" : "false")
    if (content) content.hidden = !open
  }
}
