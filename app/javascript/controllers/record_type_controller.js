import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["standardField", "mxFields", "priority", "host", "data"]

  connect() {
    const selectElement = this.element.querySelector('select[name="dns_record[record_type]"]')
    
    // Add backup manual event listener and debug all events
    if (selectElement) {
      // Listen for key events to debug
      try {
        selectElement.addEventListener('change', (event) => {
          this.toggleFields(event)
        })
        
        selectElement.addEventListener('click', (event) => {
        })
        
      } catch (error) {
        console.error("❌ Error adding event listeners:", error)
      }
    }
    
    this.toggleFields()
    this.bindMxInputs()
    
    // Ensure initial state is correct
    setTimeout(() => {
      this.toggleFields()
    }, 100)
  }

  toggleFields(event) {
    // Get the select element - it might be the event target or we need to find it
    const selectElement = event?.target || this.element.querySelector('select[name="dns_record[record_type]"]')
    
    if (!selectElement) {
      console.error("Could not find record type select element")
      return
    }
    
    const recordType = selectElement.value
    
    // Check if targets exist
    if (!this.hasStandardFieldTarget || !this.hasMxFieldsTarget) {
      return
    }
    
    if (recordType === "MX") {
      // Hide standard field
      this.standardFieldTarget.classList.add("hidden")
      
      // Show MX fields
      this.mxFieldsTarget.classList.remove("hidden")
      
      // Disable standard data field so it doesn't submit
      const standardDataField = this.standardFieldTarget.querySelector('input[name="dns_record[data]"]')
      if (standardDataField) {
        standardDataField.disabled = true
        standardDataField.value = ""
      }
      
      // Enable MX data field
      if (this.hasDataTarget) {
        this.dataTarget.disabled = false
      }
    } else {
      // Show standard field
      this.standardFieldTarget.classList.remove("hidden")
      
      // Hide MX fields
      this.mxFieldsTarget.classList.add("hidden")
      
      // Enable standard data field
      const standardDataField = this.standardFieldTarget.querySelector('input[name="dns_record[data]"]')
      if (standardDataField) {
        standardDataField.disabled = false
      }
      
      // Disable and clear MX fields
      if (this.hasPriorityTarget) this.priorityTarget.value = ""
      if (this.hasHostTarget) this.hostTarget.value = ""
      if (this.hasDataTarget) {
        this.dataTarget.disabled = true
        this.dataTarget.value = ""
      }
    }
  }

  bindMxInputs() {
    // Bind input events to combine priority and host into data field
    if (this.hasPriorityTarget && this.hasHostTarget && this.hasDataTarget) {
      this.priorityTarget.addEventListener('input', this.combineMxData.bind(this))
      this.hostTarget.addEventListener('input', this.combineMxData.bind(this))
    }
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

  // Add form submission handler to ensure MX data is combined before submission
  handleFormSubmit(event) {
    const selectElement = this.element.querySelector('select[name="dns_record[record_type]"]')
    const recordType = selectElement?.value
    
    if (recordType === "MX") {
      this.combineMxData()
    } else {
      // For non-MX records, check if standard data field has value
      const standardDataField = this.standardFieldTarget?.querySelector('input[name="dns_record[data]"]')
      
    }
    
  }
}