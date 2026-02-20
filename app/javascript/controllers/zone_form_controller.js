import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zoneName", "primaryNs", "adminEmail"]

  connect() {
    this.nsManuallyEdited = false
    this.adminManuallyEdited = false

    this.primaryNsTarget.addEventListener("input", () => { this.nsManuallyEdited = true })
    this.adminEmailTarget.addEventListener("input", () => { this.adminManuallyEdited = true })
  }

  updateDefaults() {
    const zone = this.zoneNameTarget.value.trim()
    if (!zone) return

    if (!this.nsManuallyEdited) {
      this.primaryNsTarget.value = `ns01.${zone}.`
    }
    if (!this.adminManuallyEdited) {
      this.adminEmailTarget.value = `admin.${zone}.`
    }
  }
}
