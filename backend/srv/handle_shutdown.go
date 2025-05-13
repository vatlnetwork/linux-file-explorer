package srv

import (
	"context"
	"golang-web-core/util"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
)

func (s *Server) RegisterHandleShutdown(httpServer *http.Server) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	go func() {
		for sig := range c {
			if sig == os.Interrupt {
				log.Println("Gracefully shutting down...")
				err := httpServer.Shutdown(ctx)
				if err != nil {
					util.LogFatal(err)
				}
			}
		}
	}()
}
