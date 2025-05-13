package cfg

import "os"

func GetArg(arg string) (isPresent bool, value string) {
	args := os.Args[1:]

	for i, a := range args {
		if a == arg {
			isPresent = true
			value = args[i+1]
		}
	}

	return
}
