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

func SetVariables() {
	log.Infoln("Setting Environment Variables")

	setEnv("ADMIN_PASSWORD", adminPass)
	setEnv("ADMIN_USERNAME", adminUser)
	setEnv("BIND_IP", "0.0.0.0")
	setEnv("DEFAULT_PORT", steamPort)
	setEnv("GAME_VERSION", gameVersion)
	setEnv("GC_CONFIG", gcConfig)
	setEnv("MAX_RAM", maxRam)
	setEnv("RCON_PASSWORD", rconPassword)
	setEnv("RCON_PORT", rconPort)
	setEnv("SERVER_NAME", serverName)

	writeToFile(configDir+"ip.txt", []byte(os.Getenv("BIND_IP")))

	log.Infoln("Environment Variables set!")
}

func ApplyPreInstallConfig() {
	log.Infoln("Applying PreInstall Config")

	gameVersion := os.Getenv("GAME_VERSION")
	replaceTextInFile(steamInstallFile, "beta .*", "beta "+gameVersion)

	log.Infoln("PreInstall Config set!")
}

func UpdateServer() {
	log.Infoln("Updating SteamCMD and Zomboid Dedicated Server")

	saveShellCmd("steamcmd.sh", "+runscript", steamInstallFile)

	log.Infoln("Update complete!")
}

func TestFirstRun() {
	log.Infoln("Testing First Run")

	done := make(chan bool, 1)

	go startServerKillProcess()

	go startServer(done)

	<-done

	log.Infoln("Test Run Complete!")
}

func ApplyPostInstallConfig() {
	log.Infoln("Applying PostInstall Config")

	applyServerConfigChanges()

	applyJvmConfigChanges()

	log.Infoln("PostInstall Config Applied!")
}

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
		noSteam,
	)

	log.Infoln("Server Run Complete!")
	done <- true
}
