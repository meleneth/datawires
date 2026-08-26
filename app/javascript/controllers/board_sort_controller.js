import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { columnUrl: String, cardUrl: String }

  dragStart(event) {
    const item = event.currentTarget
    event.stopPropagation()
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("application/json", JSON.stringify({
      type: item.dataset.boardSortType,
      id: item.dataset.boardSortId,
      columnId: item.dataset.boardSortColumnId
    }))
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  async drop(event) {
    event.preventDefault()
    event.stopPropagation()
    const dragged = JSON.parse(event.dataTransfer.getData("application/json"))
    const target = event.currentTarget.dataset
    if (dragged.type !== target.boardSortType || dragged.id === target.boardSortId) return

    const body = new URLSearchParams()
    const url = dragged.type === "column" ? this.columnUrlValue : this.cardUrlValue
    if (dragged.type === "column") {
      body.set("column_id", dragged.id)
      body.set("target_column_id", target.boardSortId)
    } else {
      body.set("column_id", dragged.columnId)
      body.set("card_id", dragged.id)
      body.set("target_column_id", target.boardSortColumnId)
      body.set("target_card_id", target.boardSortId)
    }
    await fetch(url, {
      method: "PATCH",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/x-www-form-urlencoded", "Accept": "text/vnd.turbo-stream.html" },
      body
    })
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
