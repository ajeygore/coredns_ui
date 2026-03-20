import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["standardField", "mxFields", "soaFields", "priority", "host", "data",
                     "soaNs", "soaMbox", "soaRefresh", "soaRetry", "soaExpire", "soaMinttl", "soaData"]

  connect() {
    const selectElement = this.element.querySelector('select[name="dns_record[record_type]"]')

    if (selectElement) {
      selectElement.addEventListener('change', (event) => {
        this.toggleFields(event)
      })
    }

    this.toggleFields()
    this.bindMxInputs()
    this.bindSoaInputs()

    setTimeout(() => {
      this.toggleFields()
    }, 100)
  }

  toggleFields(event) {
    const selectElement = event?.target || this.element.querySelector('select[name="dns_record[record_type]"]')

    if (!selectElement) return

    const recordType = selectElement.value

    if (!this.hasStandardFieldTarget || !this.hasMxFieldsTarget || !this.hasSoaFieldsTarget) return

    // Hide all field groups first
    this.standardFieldTarget.classList.add("hidden")
    this.mxFieldsTarget.classList.add("hidden")
    this.soaFieldsTarget.classList.add("hidden")

    // Disable all data fields
    const standardDataField = this.standardFieldTarget.querySelector('input[name="dns_record[data]"]')
    if (standardDataField) {
      standardDataField.disabled = true
      standardDataField.value = ""
    }
    if (this.hasDataTarget) {
      this.dataTarget.disabled = true
      this.dataTarget.value = ""
    }
    if (this.hasSoaDataTarget) {
      this.soaDataTarget.disabled = true
      this.soaDataTarget.value = ""
    }

    if (recordType === "MX") {
      this.mxFieldsTarget.classList.remove("hidden")
      if (this.hasDataTarget) this.dataTarget.disabled = false
    } else if (recordType === "SOA") {
      this.soaFieldsTarget.classList.remove("hidden")
      if (this.hasSoaDataTarget) this.soaDataTarget.disabled = false
    } else {
      this.standardFieldTarget.classList.remove("hidden")
      if (standardDataField) standardDataField.disabled = false
    }

    // Clear unused fields
    if (recordType !== "MX") {
      if (this.hasPriorityTarget) this.priorityTarget.value = ""
      if (this.hasHostTarget) this.hostTarget.value = ""
    }
  }

  bindMxInputs() {
    if (this.hasPriorityTarget && this.hasHostTarget && this.hasDataTarget) {
      this.priorityTarget.addEventListener('input', this.combineMxData.bind(this))
      this.hostTarget.addEventListener('input', this.combineMxData.bind(this))
    }
  }

  bindSoaInputs() {
    const soaFields = ['soaNs', 'soaMbox', 'soaRefresh', 'soaRetry', 'soaExpire', 'soaMinttl']
    soaFields.forEach(field => {
      const hasTarget = `has${field.charAt(0).toUpperCase() + field.slice(1)}Target`
      if (this[hasTarget]) {
        this[`${field}Target`].addEventListener('input', this.combineSoaData.bind(this))
      }
    })
  }

  combineMxData() {
    if (this.hasPriorityTarget && this.hasHostTarget && this.hasDataTarget) {
      const priority = this.priorityTarget.value.trim()
      const host = this.hostTarget.value.trim()

      if (priority && host) {
        this.dataTarget.value = `${priority} ${host}`
      } else {
        this.dataTarget.value = ''
      }
    }
  }

  combineSoaData() {
    if (!this.hasSoaDataTarget) return

    const ns = this.hasSoaNsTarget ? this.soaNsTarget.value.trim() : ''
    const mbox = this.hasSoaMboxTarget ? this.soaMboxTarget.value.trim() : ''
    const refresh = this.hasSoaRefreshTarget ? this.soaRefreshTarget.value.trim() : '3600'
    const retry = this.hasSoaRetryTarget ? this.soaRetryTarget.value.trim() : '600'
    const expire = this.hasSoaExpireTarget ? this.soaExpireTarget.value.trim() : '86400'
    const minttl = this.hasSoaMinttlTarget ? this.soaMinttlTarget.value.trim() : '300'

    if (ns && mbox) {
      this.soaDataTarget.value = `${ns} ${mbox} ${refresh} ${retry} ${expire} ${minttl}`
    } else {
      this.soaDataTarget.value = ''
    }
  }

  handleFormSubmit(event) {
    const selectElement = this.element.querySelector('select[name="dns_record[record_type]"]')
    const recordType = selectElement?.value

    if (recordType === "MX") {
      this.combineMxData()
    } else if (recordType === "SOA") {
      this.combineSoaData()
    }
  }
}
