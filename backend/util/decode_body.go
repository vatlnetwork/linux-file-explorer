package util

import (
	"encoding/json"
	"io"
	"net/http"
)

func DecodeRequestBody(req *http.Request, decodeObject any) error {
	if req.Body == nil {
		return nil
	}

	bytes, err := io.ReadAll(req.Body)
	if err != nil {
		return err
	}

	err = json.Unmarshal(bytes, decodeObject)
	if err != nil {
		return err
	}

	return nil
}

func DecodeRequestBodyToMap(req *http.Request) (map[string]any, error) {
	if req.Body == nil {
		return make(map[string]any), nil
	}

	bytes, err := io.ReadAll(req.Body)
	if err != nil {
		return nil, err
	}

	var decoded map[string]any
	err = json.Unmarshal(bytes, &decoded)
	if err != nil {
		return nil, err
	}

	return decoded, nil
}

func DecodeFormDataToMap(req *http.Request, maxSize ...int64) (map[string]any, error) {
	size := int64(100)
	if len(maxSize) > 0 {
		size = maxSize[0]
	}

	err := req.ParseMultipartForm(size << 20)
	if err != nil {
		return nil, err
	}

	decoded := map[string]any{}
	for key, value := range req.MultipartForm.Value {
		decoded[key] = value[0]
	}

	for key, value := range req.MultipartForm.File {
		decoded[key] = value[0]
	}

	return decoded, nil
}
