package util

import (
	"fmt"
	"log"
)

func WrapColor(color, format string, parts ...any) string {
	strng := fmt.Sprintf(format, parts...)

	_, ok := Colors[color]
	if ok {
		color = Colors[color]
	}

	return fmt.Sprintf("\033[38;2;%vm%v\033[0m", color, strng)
}

func PrintColor(color, format string, parts ...any) {
	strng := fmt.Sprintf(format, parts...)

	_, ok := Colors[color]
	if ok {
		color = Colors[color]
	}

	fmt.Printf("\033[38;2;%vm%v\033[0m", color, strng)
}

func LogColor(color, format string, parts ...any) {
	strng := fmt.Sprintf(format, parts...)

	_, ok := Colors[color]
	if ok {
		color = Colors[color]
	}

	log.Printf("\033[38;2;%vm%v\033[0m", color, strng)
}

func LogFatal(err error) {
	log.Fatalf("\033[38;2;%vm%v\033[0m", Colors["red"], err)
}

func LogFatalf(format string, parts ...any) {
	strng := fmt.Sprintf(format, parts...)
	LogFatal(fmt.Errorf("%s", strng))
}

var Colors map[string]string = map[string]string{
	"green":       "0;150;50",
	"lightgreen":  "100;255;150",
	"red":         "255;0;0",
	"blue":        "0;0;255",
	"yellow":      "255;255;0",
	"lightgray":   "200;200;200",
	"lightblue":   "150;150;255",
	"lightred":    "255;150;150",
	"lightyellow": "255;255;150",
	"brown":       "139;69;19",
}
