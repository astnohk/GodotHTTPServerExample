extends Node3D

const PORT = 8888
var server = TCPServer.new()
var connections = []

func _ready():
	if server.listen(PORT) != OK:
		print("Failed to start socket server.")
		set_process(false)
		return
	print("start socket server.")

func _process(_delta):
	if server.is_connection_available():
		var conn = server.take_connection()
		if conn:
			connections.append(conn)
	for i in range(connections.size() - 1, -1, -1):
		var conn = connections[i]
		if conn and conn.get_status() != StreamPeerTCP.STATUS_NONE:
			var available_bytes = conn.get_available_bytes()
			if available_bytes > 0:
				var request_data = conn.get_string(available_bytes)
				#print("request ----------------")
				#print(request_data)
				#print("------------------------")
				var request = parse_http_request(request_data)
				print(request)
				# routing
				if request.path == "/api/get_current_camera_image":
					send_image_response(conn)
				elif request.path == "/api/control":
					control_self(conn, request.path_full)
				else:
					not_found(conn)
				conn.disconnect_from_host()
				connections.remove_at(i)
		else:
			# remove disconnected connections
			print("disconnect %d." % i)
			connections.remove_at(i)

func parse_http_request(request_data: String):
	var result = {
		"method": "",
		"path": "",
		"path_full": "",
		"version": "",
	}
	var data = request_data.split('\r\n')
	if len(data) > 0:
		var req = data[0].split(' ')
		if len(req) >= 3:
			result = {
				"method": req[0],
				"path": req[1].split('?')[0],
				"path_full": req[1],
				"version": req[2],
			}
	return result

func parse_query(path_text: String):
	var queries = {}
	var path_texts: PackedStringArray = path_text.split('?')
	if len(path_texts) == 2:
		var queries_text = path_texts[1].split('&')
		for q in queries_text:
			q = q.split('=')
			if queries.has(q[0]):
				queries[q[0]].append(q[1])
			else:
				queries[q[0]] = [q[1]]
	return queries

func send_image_response(conn: StreamPeerTCP):
	print("send current image")
	var viewport: SubViewport = get_node("SubViewport")
	var img = viewport.get_texture().get_image()
	
	var png_data = img.save_png_to_buffer()
	var headers = [
		"HTTP/1.1 200 OK",
		"Content-Type: image/png",
		"Content-Length: %d" % png_data.size(),
		"Connection: close"
	]
	var http_response_header = "\r\n".join(headers) + "\r\n\r\n"
	conn.put_data(http_response_header.to_utf8_buffer())
	conn.put_data(png_data)

func control_self(conn: StreamPeerTCP, request_path: String):
	var camera: Camera3D = get_node("SubViewport/Camera3D")
	var queries = parse_query(request_path)
	var response = "undefined"
	if queries.has("control"):
		var control: String = queries["control"][0]
		if control == "turn_left":
			camera.rotate_y(10.0/360.0 * PI)
			response = "turn_left"
		elif control == "turn_right":
			camera.rotate_y(-10.0/360.0 * PI)
			response = "turn_right"
	# response
	var body = response.to_utf8_buffer()
	var headers = [
		"HTTP/1.1 200 OK",
		"Content-Type: text/plain",
		"Content-Length: %d" % body.size(),
		"Connection: close"
	]
	var http_response_header = "\r\n".join(headers) + "\r\n\r\n"
	conn.put_data(http_response_header.to_utf8_buffer())
	conn.put_data(body)

func not_found(conn: StreamPeerTCP):
	var body = "404 Not Found".to_utf8_buffer()
	var headers = [
		"HTTP/1.1 200 OK",
		"Content-Type: text/plain",
		"Content-Length: %d" % body.size(),
		"Connection: close"
	]
	var http_response_header = "\r\n".join(headers) + "\r\n\r\n"
	conn.put_data(http_response_header.to_utf8_buffer())
	conn.put_data(body)

func _exit_tree():
	server.stop()
