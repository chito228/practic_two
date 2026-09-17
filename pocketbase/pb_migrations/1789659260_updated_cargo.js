/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_4037601690")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.role = \"logist\"",
    "deleteRule": "@request.auth.role = \"admin\"",
    "listRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\"",
    "updateRule": "@request.auth.role = \"logist\"",
    "viewRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_4037601690")

  // update collection data
  unmarshal({
    "createRule": null,
    "deleteRule": null,
    "listRule": null,
    "updateRule": null,
    "viewRule": null
  }, collection)

  return app.save(collection)
})
