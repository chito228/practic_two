/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1544125585")

  // add field
  collection.fields.addAt(1, new Field({
    "autogeneratePattern": "",
    "help": "",
    "hidden": false,
    "id": "text2526027604",
    "max": 20,
    "min": 0,
    "name": "number",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(2, new Field({
    "help": "",
    "hidden": false,
    "id": "date917377331",
    "max": "",
    "min": "",
    "name": "issuedAt",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(3, new Field({
    "help": "",
    "hidden": false,
    "id": "date730627375",
    "max": "",
    "min": "",
    "name": "expiresAt",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "help": "",
    "hidden": false,
    "id": "select105650625",
    "maxSelect": 0,
    "name": "category",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "A",
      "B",
      "C",
      "D",
      "E"
    ]
  }))

  // add field
  collection.fields.addAt(5, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_1602236899",
    "help": "",
    "hidden": false,
    "id": "relation461431942",
    "maxSelect": 0,
    "minSelect": 0,
    "name": "vehicle",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(6, new Field({
    "help": "",
    "hidden": false,
    "id": "bool3946532403",
    "name": "deleted",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1544125585")

  // remove field
  collection.fields.removeById("text2526027604")

  // remove field
  collection.fields.removeById("date917377331")

  // remove field
  collection.fields.removeById("date730627375")

  // remove field
  collection.fields.removeById("select105650625")

  // remove field
  collection.fields.removeById("relation461431942")

  // remove field
  collection.fields.removeById("bool3946532403")

  return app.save(collection)
})
