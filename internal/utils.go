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
	"bytes"
	"log"
	"os"
	"os/exec"
	"regexp"
)

const (
	steamInstallFile   = "/app/install_server.scmd"
	baseGameDir        = "/home/steam/ZomboidDedicatedServer/"
	serverFile         = baseGameDir + "start-server.sh"
	testInstallTimeout = "60"
	badStartMessage    = "ERROR"

	adminUser  = "admin"
	adminPass  = "changeme"
	serverName = "zomboid-server"
)

type captureOut struct {
	capturedOutput []byte
}

func (so *captureOut) Write(p []byte) (n int, err error) {
	so.capturedOutput = append(so.capturedOutput, p...)

	return os.Stdout.Write(p)
}

func SetVariables() {
	log.Println("Setting Environment Variables")

	setEnv("GAME_VERSION", "public")

	log.Println("Environment Variables set!")
}

func ApplyPreInstallConfig() {
	log.Println("Applying PreInstall Config")

	gameVersion := os.Getenv("GAME_VERSION")
	newText := "beta " + gameVersion

	replaceTextInFile(steamInstallFile, "beta .*", newText)

	log.Println("PreInstall Config set!")
}

func UpdateServer() {
	log.Println("Updating SteamCMD and Zomboid Dedicated Server")

	runShellCmd("steamcmd.sh", "+runscript", steamInstallFile)

	log.Println("Update complete!")
}

func TestFirstRun() {
	log.Println("Testing First Run")

	if output := saveShellCmd("timeout", testInstallTimeout, serverFile); bytes.Contains(output, []byte(badStartMessage)) {

		log.Fatalf("Detected that the Server failed to start correctly. Log attached below:\n%s\n", output)
	}

	log.Println("Test Run Complete!")
}

func ApplyPostInstallConfig() {
	log.Println("Applying PostInstall Config")
}

func StartServer() {
	log.Println("Starting Server")

	if output := saveShellCmd(serverFile,
		"-adminusername", adminUser,
		"-adminpassword", adminPass,
		"-servername", serverName); bytes.Contains(output, []byte(badStartMessage)) {

		//log.Fatalf("Detected that the Server failed to start correctly. Log attached below:\n%s\n", output)
	}

	log.Println("Server Run Complete!")
}

// Util functions //

// setEnv Set an Environment Variable
func setEnv(key string, value string) {
	if preValue := os.Getenv(key); preValue != "" {
		log.Printf("Environment Variable [%s] already set to [%s]. Skipping...\n", key, preValue)
	}

	if err := os.Setenv(key, value); err != nil {
		log.Fatalf("Failed to set Environment Variable [%s] with Value [%s]\n", key, value)
	}
}

func replaceTextInFile(fileName string, old string, new string) {
	if file, err := os.ReadFile(fileName); err != nil {
		log.Fatalf("Could not open File [%s] for editing\n", fileName)
	} else {
		re := regexp.MustCompile(old)
		outFile := re.ReplaceAllString(string(file), new)

		if err := os.WriteFile(fileName, []byte(outFile), 0444); err != nil {
			log.Fatalf("Could not write new content [%s] to file [%s]\n", outFile, fileName)
		}
	}
}

func runShellCmd(cmd string, args ...string) {
	myCmd := exec.Command(cmd, args...)

	myCmd.Stdout = os.Stdout
	myCmd.Stderr = os.Stderr

	log.Printf("Executing command: [%s]\n", myCmd)

	if err := myCmd.Run(); err != nil {
		log.Fatalf("Error executing command [%s]: [%s]\n", myCmd, err)
	}
}

func saveShellCmd(cmd string, args ...string) []byte {
	var cout captureOut

	myCmd := exec.Command(cmd, args...)

	myCmd.Stdout = &cout
	myCmd.Stderr = &cout

	log.Printf("Executing command: [%s]\n", myCmd)

	if err := myCmd.Run(); err != nil {
		log.Fatalf("Error executing command [%s]: [%s]\n", myCmd, err)
	}

	return cout.capturedOutput
}
