package util

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
)

func SendGetRequest(url string, params url.Values) ([]byte, int, error) {
	request, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, http.StatusInternalServerError, err
	}
	request.URL.RawQuery = params.Encode()
	request.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(request)
	if err != nil {
		return nil, http.StatusInternalServerError, err
	}

	bytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, http.StatusInternalServerError, err
	}

	if !(resp.StatusCode >= 200 && resp.StatusCode < 300) {
		return nil, resp.StatusCode, fmt.Errorf("%v", string(bytes))
	}

	return bytes, resp.StatusCode, nil
}
