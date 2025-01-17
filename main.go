package main

//#include "./main.h"
import "C"

import (
	"os"
	"unsafe"

	fzf "github.com/junegunn/fzf/src"
	"github.com/junegunn/fzf/src/protector"
	"github.com/mattn/go-shellwords"
)

var revision string

//ExportMainObjectiveC main function bridge for objective c
//export ExportMainObjectiveC
func ExportMainObjectiveC(argc C.int, argv, envp **C.char) C.int {
	//convert args from iOS args to golang's os.Args
	// args := goStrings(argc, argv)

	// //make a commadline from args
	// commandLine := flag.NewFlagSet(args[0], flag.ExitOnError)

	// //args declaration
	// testCmd := commandLine.String("t", "test", "command line string args test")

	// //parse args
	// commandLine.Parse(args[1:])

	// //show the result
	// fmt.Println("hello, iOS")
	// fmt.Printf("command line -t input: %s\n", *testCmd)

	// Start real

	protector.Protect()

	opts := fzf.DefaultOptions()

	// Options from Env var
	words, _ := shellwords.Parse(os.Getenv("FZF_DEFAULT_OPTS"))
	if len(words) > 0 {
		fzf.ParseOptionsArgs(opts, words)
	}

	args := goStrings(argc, argv)

	// Options from command-line arguments
	fzf.ParseOptionsArgs(opts, args[1:])

	fzf.PostProcessOptions(opts)

	fzf.Run(opts, revision)

	return 0
}

func goStrings(argc C.int, argv **C.char) []string {
	length := int(argc)
	tmpSlice := (*[1 << 9]*C.char)(unsafe.Pointer(argv))[:length:length]
	goStrings := make([]string, length)
	for i, s := range tmpSlice {
		goStrings[i] = C.GoString(s)
	}
	return goStrings
}

func main() {}
