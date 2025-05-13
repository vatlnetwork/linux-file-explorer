package main

import (
	"golang-web-core/srv"
	"golang-web-core/srv/cfg"
	"golang-web-core/util"
)

func main() {
	file := "default"
	_, cfgFlag := cfg.GetArg("--config")
	if cfgFlag != "" {
		file = cfgFlag
	}

	cfg, err := cfg.FromFile(file)
	if err != nil {
		util.LogFatal(err)
	}

	srv, err := srv.NewServer(cfg)
	if err != nil {
		util.LogFatal(err)
	}

	if err := srv.Start(); err != nil {
		util.LogFatal(err)
	}
}
