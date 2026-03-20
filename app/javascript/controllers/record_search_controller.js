import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "table"]

  filter() {
    const query = this.inputTarget.value.toLowerCase()

    this.tableTargets.forEach(table => {
      const rows = table.querySelectorAll("tbody tr")
      let visibleCount = 0

      rows.forEach(row => {
        const text = row.textContent.toLowerCase()
        const match = text.includes(query)
        row.style.display = match ? "" : "none"
        if (match) visibleCount++
      })

      const container = table.closest(".table-container")
      if (container) {
        container.style.display = visibleCount > 0 ? "" : "none"
      }
    })
  }
}
