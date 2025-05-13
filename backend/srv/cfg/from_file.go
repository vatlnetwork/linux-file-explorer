package cfg

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func FromFile(file string) (Config, error) {
	file = strings.TrimSuffix(file, ".json")

	if strings.Contains(file, "/") {
		parts := strings.Split(file, "/")
		file = parts[len(parts)-1]
	}

	if strings.Contains(file, "\\") {
		parts := strings.Split(file, "\\")
		file = parts[len(parts)-1]
	}

	file = fmt.Sprintf("configs/%v.json", file)

	bytes, err := os.ReadFile(file)
	if err != nil {
		return Config{}, err
	}

	config := Config{}
	err = json.Unmarshal(bytes, &config)
	if err != nil {
		return Config{}, err
	}

	err = config.Verify()
	if err != nil {
		return Config{}, err
	}

	return config, nil
}
