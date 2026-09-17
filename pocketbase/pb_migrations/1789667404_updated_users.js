/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // update collection data
  unmarshal({
    "listRule": "@request.auth.role = \"admin\" || id = @request.auth.id",
    "updateRule": "@request.auth.role = \"admin\"",
    "viewRule": "@request.auth.role = \"admin\" || id = @request.auth.id"
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("_pb_users_auth_")

  // update collection data
  unmarshal({
    "listRule": "(id = @request.auth.id || @request.auth.role = \"admin\") && (deleted = false)",
    "updateRule": "(id = @request.auth.id || @request.auth.role = \"admin\") && (deleted = false)",
    "viewRule": "(id = @request.auth.id || @request.auth.role = \"admin\") && (deleted = false)"
  }, collection)

  return app.save(collection)
})
