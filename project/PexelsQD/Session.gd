class_name Session

signal notified(message)
signal photo_fetched(texture)

const MESSAGE := {
	"http": "ERROR\nresult: {0}\nrequest_code: {1}\nbody: {3}",
	"json": "ERROR\nerror: {0}\nerror_line: {1}\nerror_string: {2}",
	"result": "ERROR\nerror: {0}",
	"zero": "WARNING\nCouldn't find any results for `{0}`, please try a again!"
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
var _image := Image.new()
var _image_funcs := {
	"jpg": funcref(_image, "load_jpg_from_buffer"),
	"png": funcref(_image, "load_png_from_buffer")
}
var _config_file: ConfigFile = null
var _http_request: HTTPRequest = null


func _init(config_file: ConfigFile, http_request: HTTPRequest) -> void:
	_config_file = config_file
	_http_request = http_request
	_image_funcs.jpeg = _image_funcs.jpg
	
	_rng.randomize()
	_regex.compile(PATTERN)


func search(query: String) -> void:
	var is_first := _previous_query != query
	_previous_query = query
	
	var params := {
		"base_url": PHOTO.base_url,
		"query": query,
		"page": 1 if is_first else _rng.randi_range(1, _total_results)
	}
	
	var api_key: String = _config_file.get_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, "")
	PHOTO.headers[-1] = PHOTO.headers[-1].format({"api_key": api_key})
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
	elif _total_results != 0:
		for photo in body.result.photos:
			var src: String = photo.src.large2x
			var regex_result := _regex.search(src)
			if regex_result != null:
				# TODO: sometimes this might fail.
				var type := regex_result.get_string(1).to_lower()
				_http_request.request(src)
				result = yield(_http_request, "request_completed")
				_image_funcs[type].call_func(result[3])
				
				var texture := ImageTexture.new()
				texture.create_from_image(_image)
				photo.texture = texture
				emit_signal("photo_fetched", photo)
	else:
		emit_signal("notified", MESSAGE.zero.format([query]))
		emit_signal("photo_fetched", {})
