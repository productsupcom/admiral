package main

import (
	"github.com/tanji/admiral/cmd"
)

var appVersion = "undefined"

func main() {
	cmd.AppVersion = appVersion

	cmd.Execute()
}
