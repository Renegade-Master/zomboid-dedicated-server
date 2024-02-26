/*
 * Copyright 2021-2024 Renegade-Master [renegade@renegade-master.com]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package internal

import (
	log "github.com/sirupsen/logrus"
	"os"
	"os/signal"
	"syscall"
)

// SetVariables will set the required Environment Variables
func SetVariables() {
	log.Infoln("Setting Environment Variables")

	setEnvVariables()

	writeToFile(configDir+"ip.txt", []byte(os.Getenv("BIND_IP")))

	log.Infoln("Environment Variables set!")
}

// ApplyPreInstallConfig will set the Game version in the SteamCMD file
func ApplyPreInstallConfig() {
	log.Infoln("Applying PreInstall Config")

	gameVersion := os.Getenv("GAME_VERSION")
	replaceTextInFile(steamInstallFile, "beta .*", "beta "+gameVersion)

	log.Infoln("PreInstall Config set!")
}

// UpdateServer will use SteamCMD to install or update the Server
func UpdateServer() {
	log.Infoln("Updating SteamCMD and Zomboid Dedicated Server")

	saveShellCmd("steamcmd.sh", "+runscript", steamInstallFile)

	log.Infoln("Update complete!")
}

// TestFirstRun will start the Server with a timeout so that the Server files are generated
func TestFirstRun() {
	log.Infoln("Testing First Run")

	done := make(chan bool, 1)

	go startServerKillProcess()

	go startServer(done)

	<-done

	log.Infoln("Test Run Complete!")
}

// ApplyPostInstallConfig applies the Server configuration options that use
func ApplyPostInstallConfig() {
	log.Infoln("Applying PostInstall Config")

	applyServerConfigChanges()

	applyJvmConfigChanges()

	log.Infoln("PostInstall Config Applied!")
}

// StartManagedServer starts the Server with handling for interrupts
func StartManagedServer() {
	log.Infoln("Starting Server wit Signal Handling. Press CTRL+C to quit.")

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	done := make(chan bool, 1)

	go func() {
		sig := <-sigs

		log.Warnf("Received Signal [%s]. Beginning shutdown using RCON...\n", sig)

		rconAddress := "127.0.0.1:" + os.Getenv("RCON_PORT")
		saveShellCmd(rcon,
			"--address", rconAddress,
			"--password", os.Getenv("RCON_PASSWORD"),
			"quit")

		done <- true
	}()

	startServer(done)

	<-done

	log.Infoln("Server stopped!")
}

func startServer(done chan bool) {
	log.Infoln("Starting Server")

	saveShellCmd(serverFile,
		"-adminpassword", os.Getenv("ADMIN_PASSWORD"),
		"-adminusername", os.Getenv("ADMIN_USERNAME"),
		"-cachedir="+configDir,
		"-ip", os.Getenv("BIND_IP"),
		"-port", os.Getenv("DEFAULT_PORT"),
		"-servername", os.Getenv("SERVER_NAME"),
		"-steamvac", steamVac,
		"-udpport", rakNetPort,
		getSteamUse(),
	)

	log.Infoln("Server Run Complete!")
	done <- true
}
