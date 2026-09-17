/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1364849191")

  // add field
  collection.fields.addAt(1, new Field({
    "autogeneratePattern": "",
    "help": "",
    "hidden": false,
    "id": "text1579384326",
    "max": 150,
    "min": 0,
    "name": "name",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(2, new Field({
    "autogeneratePattern": "",
    "help": "",
    "hidden": false,
    "id": "text223244161",
    "max": 300,
    "min": 0,
    "name": "address",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": true,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(3, new Field({
    "help": "",
    "hidden": false,
    "id": "select2363381545",
    "maxSelect": 0,
    "name": "type",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "dry",
      "cold",
      "hazardous"
    ]
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "help": "",
    "hidden": false,
    "id": "number3051925876",
    "max": null,
    "min": null,
    "name": "capacity",
    "onlyInt": false,
    "presentable": false,
    "required": true,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(5, new Field({
    "help": "",
    "hidden": false,
    "id": "number3248729583",
    "max": null,
    "min": null,
    "name": "currentLoad",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(6, new Field({
    "cascadeDelete": false,
    "collectionId": "_pb_users_auth_",
    "help": "",
    "hidden": false,
    "id": "relation4196672953",
    "maxSelect": 0,
    "minSelect": 0,
    "name": "manager",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(7, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_4037601690",
    "help": "",
    "hidden": false,
    "id": "relation1005475697",
    "maxSelect": 100,
    "minSelect": 0,
    "name": "cargo",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(8, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_96911357",
    "help": "",
    "hidden": false,
    "id": "relation852869811",
    "maxSelect": 100,
    "minSelect": 0,
    "name": "routes",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(9, new Field({
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
  const collection = app.findCollectionByNameOrId("pbc_1364849191")

  // remove field
  collection.fields.removeById("text1579384326")

  // remove field
  collection.fields.removeById("text223244161")

  // remove field
  collection.fields.removeById("select2363381545")

  // remove field
  collection.fields.removeById("number3051925876")

  // remove field
  collection.fields.removeById("number3248729583")

  // remove field
  collection.fields.removeById("relation4196672953")

  // remove field
  collection.fields.removeById("relation1005475697")

  // remove field
  collection.fields.removeById("relation852869811")

  // remove field
  collection.fields.removeById("bool3946532403")

  return app.save(collection)
})
