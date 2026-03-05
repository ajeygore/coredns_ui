import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zoneName", "primaryNs", "adminEmail"]
  static values = { defaultNs: String, defaultEmail: String }

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
      this.primaryNsTarget.value = this.defaultNsValue || `ns01.${zone}.`
    }
    if (!this.adminManuallyEdited) {
      this.adminEmailTarget.value = this.defaultEmailValue || `admin.${zone}.`
    }
  }
}
