import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]
  static values = { defaultValue: String }

  connect() {
    const value = this.defaultValue || this.activeTriggerValue || this.firstTriggerValue
    if (value) this.activate(value)
  }

  select(event) {
    this.activate(event.params.value || event.currentTarget.getAttribute("data-retro-ui--tabs-value-param"))
  }

  activate(value) {
    this.triggerTargets.forEach((trigger) => {
      const active = this.triggerValue(trigger) === value
      trigger.dataset.state = active ? "active" : "inactive"
      trigger.setAttribute("aria-selected", active ? "true" : "false")
    })

    this.contentTargets.forEach((content) => {
      content.hidden = this.contentValue(content) !== value
    })
  }

  get defaultValue() {
    return this.hasDefaultValueValue ? this.defaultValueValue : null
  }

  get activeTriggerValue() {
    const trigger = this.triggerTargets.find((item) => item.dataset.state === "active")
    return trigger ? this.triggerValue(trigger) : null
  }

  get firstTriggerValue() {
    return this.triggerTargets[0] ? this.triggerValue(this.triggerTargets[0]) : null
  }

  triggerValue(trigger) {
    return trigger.getAttribute("data-retro-ui--tabs-value-param")
  }

  contentValue(content) {
    return content.getAttribute("data-retro-ui--tabs-value")
  }
}
