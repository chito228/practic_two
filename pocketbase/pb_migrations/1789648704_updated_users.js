/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // update collection data
  unmarshal({
    "createRule": null,
    "deleteRule": null,
    "listRule": null,
    "updateRule": null,
    "viewRule": null
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.role = \"admin\"",
    "deleteRule": "@request.auth.role = \"admin\"",
    "listRule": "(id = @request.auth.id || @request.auth.role = \"admin\") && (deleted = false)",
    "updateRule": "(id = @request.auth.id || @request.auth.role = \"admin\") && (deleted = false)",
    "viewRule": "(id = @request.auth.id || @request.auth.role = \"admin\") && (deleted = false)"
  }, collection)

  return app.save(collection)
})
