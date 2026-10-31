// upupa_backend/cmd/serve.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/spf13/cobra"
)

func NewServeCommand(handler http.Handler, version string) *cobra.Command {
	var httpAddr string
	var showVersion bool

	command := &cobra.Command{
		Use:          "serve",
		Short:        "Starts the Upupa web server",
		SilenceUsage: true,
		RunE: func(command *cobra.Command, args []string) error {
			if showVersion {
				fmt.Printf("Upupa Backend Version: %s\n", version)
				return nil
			}

			if httpAddr == "" {
				httpAddr = "127.0.0.1:8888"
			}

			fmt.Printf("Server starting on http://%s...\n", httpAddr)

			err := http.ListenAndServe(httpAddr, handler)
			if errors.Is(err, http.ErrServerClosed) {
				return nil
			}

			return err
		},
	}

	command.PersistentFlags().StringVar(
		&httpAddr,
		"http",
		"127.0.0.1:8888",
		"TCP address to listen for the HTTP server (e.g. 127.0.0.1:8888)",
	)

	command.PersistentFlags().BoolVarP(
		&showVersion,
		"version",
		"v",
		false,
		"Print the version of Upupa backend",
	)

	return command
}
