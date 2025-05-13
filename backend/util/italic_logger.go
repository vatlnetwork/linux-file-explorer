package util

import (
	"fmt"
	"log"
)

func WrapItalicColor(color, format string, parts ...any) string {
	_, ok := Colors[color]
	if ok {
		color = Colors[color]
	}

	return fmt.Sprintf("\033[3m\033[38;2;%vm%v\033[0m", color, fmt.Sprintf(format, parts...))
}

func LogItalic(format string, parts ...any) {
	log.Printf("\033[3m%v\033[0m", fmt.Sprintf(format, parts...))
}

func LogItalicColor(color string, format string, parts ...any) {
	_, ok := Colors[color]
	if ok {
		color = Colors[color]
	}

	log.Printf("\033[3m\033[38;2;%vm%v\033[0m", color, fmt.Sprintf(format, parts...))
}
