class_name Session

#signal photo_fetched(message)

const MESSAGES := {
	"http": "ERROR\nresult: {0}\nrequest_code: {1}\nbody: {3}",
	"json": "ERROR\nerror: {0}\nerror_line: {1}\nerror_string: {2}",
	"result": "ERROR\nerror: {0}",
	"zero": "ERROR\nCouldn't find any results for `{0}`, please try a again!",
	"unsupported": "ERROR\n Skipping! Fetched an unsupported image type from {0}.",
	"unknown": "ERROR\n Something went wrong!"
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


func search(query: String) -> Dictionary:
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
	
	if result[0] != HTTPRequest.RESULT_SUCCESS or not result[1] in [HTTPClient.RESPONSE_OK, HTTPClient.RESPONSE_UNAUTHORIZED]:
		return {"error": MESSAGES.http.format(result)}
	
	var body := JSON.parse(result[3].get_string_from_utf8())
	if body.error != OK:
		return {"error": MESSAGES.json.format([body.error, body.error_line, body.error_string])}
	
	if body.result.has("error"):
		return {"error": MESSAGES.result.format([body.result.error])}
	
	if is_first:
		_total_results = body.result.total_results
		return search(params.query)
	elif _total_results > 0:
		for photo in body.result.photos:
			var src: String = photo.src.large2x
			var regex_result := _regex.search(src)
			if regex_result != null:
				var type := regex_result.get_string(1).to_lower()
				_http_request.request(src)
				result = yield(_http_request, "request_completed")
				
				if result[0] != HTTPRequest.RESULT_SUCCESS or not result[1] in [HTTPClient.RESPONSE_OK, HTTPClient.RESPONSE_UNAUTHORIZED]:
					return {"error": MESSAGES.http.format(result)}
				
				_image_funcs[type].call_func(result[3])
				photo.texture = ImageTexture.new()
				photo.texture.create_from_image(_image)
				return photo
			else:
				return {"error": MESSAGES.unsupported.format(src)}
	else:
		return {"error": MESSAGES.zero.format([query])}
	
	# Function should never reach this code
	return MESSAGES.unknown
