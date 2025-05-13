package cfg

import (
	"fmt"
	"os"
)

type Environment string

const (
	Development Environment = "development"
	Production  Environment = "production"
)

type Config struct {
	Port     int         `json:"port"`
	SSL      SSL         `json:"ssl"`
	PublicFS bool        `json:"enablePublicFS"`
	Env      Environment `json:"env"`
}

func (c Config) IsSSL() bool {
	return c.SSL.CertPath != "" && c.SSL.KeyPath != ""
}

type SSL struct {
	CertPath string `json:"certPath"`
	KeyPath  string `json:"keyPath"`
}

func (s *SSL) SetCertPath(path string) error {
	_, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("the cert path you specified (%v) does not exist", path)
		}
		return err
	}

	s.CertPath = path

	return nil
}

func (s *SSL) SetKeyPath(path string) error {
	_, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("the key path you specified (%v) does not exist", path)
		}
		return err
	}

	s.KeyPath = path

	return nil
}
