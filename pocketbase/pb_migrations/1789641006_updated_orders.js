/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3527180448")

  // add field
  collection.fields.addAt(1, new Field({
    "autogeneratePattern": "",
    "help": "",
    "hidden": false,
    "id": "text2560262659",
    "max": 50,
    "min": 0,
    "name": "orderNumber",
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
    "id": "text2773469857",
    "max": 0,
    "min": 0,
    "name": "cargoDescription",
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
    "id": "number130897217",
    "max": null,
    "min": null,
    "name": "weight",
    "onlyInt": false,
    "presentable": false,
    "required": true,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "help": "",
    "hidden": false,
    "id": "number3113930206",
    "max": null,
    "min": null,
    "name": "volume",
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
    "id": "date2671580400",
    "max": "",
    "min": "",
    "name": "shippingDate",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(6, new Field({
    "help": "",
    "hidden": false,
    "id": "date1617488410",
    "max": "",
    "min": "",
    "name": "deliveryDate",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  // add field
  collection.fields.addAt(7, new Field({
    "help": "",
    "hidden": false,
    "id": "select2063623452",
    "maxSelect": 0,
    "name": "status",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "select",
    "values": [
      "in_transit",
      "delivered",
      "cancelled"
    ]
  }))

  // add field
  collection.fields.addAt(8, new Field({
    "cascadeDelete": false,
    "collectionId": "pbc_2442875294",
    "help": "",
    "hidden": false,
    "id": "relation3343123541",
    "maxSelect": 0,
    "minSelect": 0,
    "name": "client",
    "presentable": false,
    "required": true,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(9, new Field({
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
  collection.fields.addAt(10, new Field({
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
  collection.fields.addAt(11, new Field({
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
  const collection = app.findCollectionByNameOrId("pbc_3527180448")

  // remove field
  collection.fields.removeById("text2560262659")

  // remove field
  collection.fields.removeById("text2773469857")

  // remove field
  collection.fields.removeById("number130897217")

  // remove field
  collection.fields.removeById("number3113930206")

  // remove field
  collection.fields.removeById("date2671580400")

  // remove field
  collection.fields.removeById("date1617488410")

  // remove field
  collection.fields.removeById("select2063623452")

  // remove field
  collection.fields.removeById("relation3343123541")

  // remove field
  collection.fields.removeById("relation1005475697")

  // remove field
  collection.fields.removeById("relation852869811")

  // remove field
  collection.fields.removeById("bool3946532403")

  return app.save(collection)
})
