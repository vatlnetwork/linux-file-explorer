package domain

import "errors"

type App struct {
	Name       string `json:"name"`
	IconPath   string `json:"iconPath"`
	BinaryPath string `json:"binaryPath"`
}

func (a App) Run(args []string) error {
	return errors.New("not implemented")
}
