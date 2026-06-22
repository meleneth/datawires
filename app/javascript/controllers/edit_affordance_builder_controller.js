import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["path", "collection", "collectionNote"]

  connect() {
    this.sync()
  }

  sync() {
    const selectedOption = this.pathTarget.selectedOptions[0]
    const arraySelected = selectedOption?.dataset.array === "true"

    this.collectionTarget.hidden = !arraySelected
    this.collectionNoteTarget.hidden = arraySelected
  }
}
