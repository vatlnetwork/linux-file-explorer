package domain

import "errors"

type App struct {
	Name       string `json:"name"`
	IconPath   string `json:"iconPath"`
	BinaryPath string `json:"binaryPath"`
}

func (a App) Run(args []string) error {
	// TODO: implement this
	return errors.New("not implemented")
}
