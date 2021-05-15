class_name Session

signal image_fetched(texture)
signal notified(message)

const MESSAGE := {
	"http": "ERROR\nresult: {0}\nrequest_code: {1}\nbody: {3}",
	"json": "ERROR\nerror: {0}\nerror_line: {1}\nerror_string: {2}",
	"result": "ERROR\nerror: {0}"
}
const PHOTO := {
	"base_url": "https://api.pexels.com/v1",
	"search": '{base_url}/search?query={query}&page={page}&per_page=1',
	"headers": [
		"Accept: application/json",
		"Content-Type: application/json",
		"User-Agent: Pexels/GodotEngine",
		"Authorization: {api_key}"
	]
}
const PATTERN := "\\.(jpg|JPG|jpeg|JPEG|png|PNG)"

var _rng := RandomNumberGenerator.new()
var _regex := RegEx.new()
var _total_results := 0
var _previous_query := ""
var _texture := ImageTexture.new()
var _image := Image.new()
var _image_funcs := {
	"jpg": funcref(_image, "load_jpg_from_buffer"),
	"png": funcref(_image, "load_png_from_buffer")
}
var _http_request: HTTPRequest = null


func _init(api_key: String, http_request: HTTPRequest) -> void:
	PHOTO.headers[-1] = PHOTO.headers[-1].format({"api_key": api_key})
	_http_request = http_request
	_image_funcs.jpeg = _image_funcs.jpg
	
	_rng.randomize()
	_regex.compile(PATTERN)


func search(query: String) -> void:
	var is_first := _previous_query != query
	var params := {
		"base_url": PHOTO.base_url,
		"query": query,
		"page": 1 if is_first else _rng.randi_range(1, _total_results)
	}
	
	_http_request.request(PHOTO.search.format(params), PHOTO.headers)
	var result: Array = yield(_http_request, "request_completed")
	
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		emit_signal("notified", MESSAGE.http.format(result))
		return
	
	var body := JSON.parse(result[3].get_string_from_utf8())
	if body.error != OK:
		emit_signal("notified", MESSAGE.json.format([body.error, body.error_line, body.error_string]))
		return
	
	if body.result.has("error"):
		emit_signal("notified", MESSAGE.result.format([body.result.error]))
		return
	
	if is_first:
		_total_results = body.result.total_results
		search(params.query)
	else:
		var url: String = body.result.photos[0].src.large2x
		var regex_result := _regex.search(url)
		if regex_result != null:
			# TODO: something doesn't work with PNG (maybe when pictures are too large)
			var type := regex_result.get_string(1).to_lower()
			_http_request.request(url)
			result = yield(_http_request, "request_completed")
			_image_funcs[type].call_func(result[3])
			_texture.create_from_image(_image)
			emit_signal("image_fetched", _texture)
	_previous_query = query
