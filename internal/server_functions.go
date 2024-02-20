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
	"github.com/sirupsen/logrus"
	"os"
)

func SetVariables() {
	logrus.Infoln("Setting Environment Variables")

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

	logrus.Infoln("Environment Variables set!")
}

func ApplyPreInstallConfig() {
	logrus.Infoln("Applying PreInstall Config")

	gameVersion := os.Getenv("GAME_VERSION")
	replaceTextInFile(steamInstallFile, "beta .*", "beta "+gameVersion)

	logrus.Infoln("PreInstall Config set!")
}

func UpdateServer() {
	logrus.Infoln("Updating SteamCMD and Zomboid Dedicated Server")

	saveShellCmd("steamcmd.sh", "+runscript", steamInstallFile)

	logrus.Infoln("Update complete!")
}

func TestFirstRun() {
	logrus.Infoln("Testing First Run")

	go startServerKillProcess()

	StartServer()

	logrus.Infoln("Test Run Complete!")
}

func ApplyPostInstallConfig() {
	logrus.Infoln("Applying PostInstall Config")

	applyServerConfigChanges()

	applyJvmConfigChanges()

	logrus.Infoln("PostInstall Config Applied!")
}

func StartServer() {
	logrus.Infoln("Starting Server")

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

	logrus.Infoln("Server Run Complete!")
}
