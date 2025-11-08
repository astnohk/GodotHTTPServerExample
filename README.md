# Examples of HTTP Server on Godot

This is simple example of developing HTTP server on Godot game engine.
server.tscn includes `HTTPCamera` which has HTTP server based on `TCPServer`.
`HTTPCamera` is `Node3D` which has `SubViewport` to capture another view on the world without affecting main game process's view.
`HTTPCamera` has a few simple API to get current frame via HTTP connection or control it from a web browser.

## APIs

### `get_current_camera_image`

`GET /api/get_current_camera_image`

It returns current frame caught on `HTTPCamera/SubViewport/Camera3D`.
You can change the image size by changing properties of `HTTPCamera/SubViewport` because it rely on `SubViewport`'s texture.

### `control`

`GET /api/control`

It controls `HTTPCamera` by URL queries.

#### `?control=turn_left`

Turn the camera to 10 degrees left.

#### `?control=turn_right`

Turn the camera to 10 degrees right.

## LICENSE

MIT.
