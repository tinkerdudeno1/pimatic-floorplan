module.exports = {
  title: "pimatic-floorplan config options"
  Floorplan: {
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:{
      floorplan:
        description: "the sgv filename with the floorplan"
        type: "string"
      devices:
        description: "list of devices used in the floorplan"
        format: "table"
        type: "array"
        default: []
        required: ["name", "pimatic_device_id"]
        items:
          type: "object"
          properties:
            name:
              description: "The device name"
              type: "string"
            type:
              description: "The gui type of device"
              enum: ["switch","button","presence","contact","light","sensor"]
            pimatic_device_id:
              descpription: "The pimatic device Id"
              type: "string"
            pimatic_attribute_name:
              description: "The attribute name of the Pimatic device like state, presence or temperature"
              type: "string"
            acronym:
              description: "Add acronym before sensor value (if available)"
              type: "boolean"
              required: false
            unit:
              description: "Add unit after sensor value (if available)"
              type: "boolean"
              required: false
      colors:
        description: "Colors used in floorplan device"
        format: "table"
        type: "array"
        default: []
        required: ["name","color"]
        items:
          type: "object"
          properties:
            name:
              description: "Name of device state"
              enum: ["switchOff", "presenceOff", "contactOff","buttonOff", "lightOff"]
            color:
              description: "The hex color for the selected off-state"
              type: "string"
    }
  }
}
