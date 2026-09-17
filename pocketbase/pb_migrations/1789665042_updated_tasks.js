/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2602490748")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.role = \"manager\" || @request.auth.role = \"admin\"",
    "listRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\" || @request.auth.role = \"admin\"",
    "updateRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\" || @request.auth.role = \"admin\"",
    "viewRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\" || @request.auth.role = \"admin\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2602490748")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.role = \"manager\"",
    "listRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\"",
    "updateRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\"",
    "viewRule": "@request.auth.role = \"manager\" || @request.auth.role = \"logist\""
  }, collection)

  return app.save(collection)
})
