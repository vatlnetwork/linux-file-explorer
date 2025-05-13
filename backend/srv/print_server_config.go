package srv

import (
	"fmt"
	"golang-web-core/util"
	"strings"
)

type configLine struct {
	label      string
	value      any
	indent     int
	valueColor string
}

func newLine(label string, value any, indent int, valueColor string) configLine {
	return configLine{label: label, value: value, indent: indent, valueColor: valueColor}
}

func (l configLine) String() string {
	return fmt.Sprintf("%v[%v]: %v", strings.Repeat("   ", l.indent), util.WrapItalicColor("lightgray", "%v", l.label), util.WrapColor(l.valueColor, "%v", l.value))
}

func printLine(indent int, label string, value any, valueColor string) {
	fmt.Println(newLine(label, value, indent, valueColor).String())
}

func PrintServerConfig(server *Server) {
	c := server.Config

	printLine(0, "Server Config", "", "")
	printLine(1, "Environment", c.Env, "brown")
	printLine(1, "Port", c.Port, "lightgreen")
	printLine(1, "Public FS Enabled", c.PublicFS, "lightblue")
	printLine(1, "Using SSL", c.IsSSL(), "lightblue")
	if c.IsSSL() {
		printLine(2, "Cert Path", c.SSL.CertPath, "")
		printLine(2, "Key Path", c.SSL.KeyPath, "")
	}
	printLine(1, "Number of Routes", len(server.Routes), "lightgreen")
	fmt.Println("")
}
