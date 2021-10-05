package cmd

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/spf13/cobra"
	"github.com/tanji/admiral/datastructs"
)

func init() {
	rootCmd.AddCommand(genPromSDFile)
}

var genPromSDFile = &cobra.Command{
	Use:     "prometheus",
	Aliases: []string{"prom"},
	Short:   "Output prometheus compatible SD file structure",
	Example: "admiral prometheus > prometheus_file_sd.json",
	Run:     genPromSDFileFunc,
}

func genPromSDFileFunc(cmd *cobra.Command, args []string) {
	prom, err := genPrometheusSDFile()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%s", prom)
}

func genPrometheusSDFile() (promSDFile []byte, err error) {
	hosts, err := DB.GetHosts()
	if err != nil {
		return nil, err
	}

	groups, err := DB.GetGroups()
	if err != nil {
		return nil, err
	}

	prom := []datastructs.Prometheus{}

	for i := range hosts {
		if hosts[i].Enabled && hosts[i].Monitored {
			for j := range groups {
				if groups[j].Name == hosts[i].DirectGroup {
					if groups[j].Enabled && groups[j].Monitored {
						pHost := datastructs.Prometheus{}
						pHost.Targets = []string{hosts[i].Hostname + "." + hosts[i].Domain}
						pHost.Labels.Group = hosts[i].DirectGroup
						pHost.Labels.InheritedGroups = hosts[i].InheritedGroups
						prom = append(prom, pHost)
					} else {
						break
					}
				}
			}
		}
	}

	promSDFile, err = json.MarshalIndent(prom, "", "    ")
	if err != nil {
		return nil, err
	}

	return promSDFile, err
}
