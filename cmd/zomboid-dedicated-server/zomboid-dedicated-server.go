package main

import (
	"log"
	utils "renegade-master/zomboid-dedicated-server/internal"
)

func main() {
	log.Println("Initialising Renegade-Master: Project Zomboid Dedicated Server")
	utils.SetVariables()

	utils.ApplyPreInstallConfig()
	utils.UpdateServer()
	utils.TestFirstRun()
	utils.ApplyPostInstallConfig()

	utils.StartServer()
}
