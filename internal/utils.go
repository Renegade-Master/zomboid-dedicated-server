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
	"github.com/mitchellh/go-ps"
	"log"
	"net"
	"os"
	"os/exec"
	"regexp"
	"time"
)

const (
	steamInstallFile   = "/app/install_server.scmd"
	baseGameDir        = "/home/steam/ZomboidDedicatedServer/"
	configDir          = "/home/steam/Zomboid/"
	modDir             = "/home/steam/ZomboidMods/"
	serverFile         = baseGameDir + "start-server.sh"
	testInstallTimeout = "60s"

	// Default configuration variables
	adminUser   = "superuser"
	adminPass   = "changeme"
	serverName  = "zomboid-server"
	steamPort   = "16261"
	rakNetPort  = "16262"
	steamVac    = "true"
	noSteam     = "-nosteam"
	gameVersion = "public"

	badMsgRegEx            = ".*(unknown option)|(Connection Startup Failed)|(expected IP address).*"
	serverProcessNameRegex = "ProjectZomboid6"
)

type captureOut struct {
	capturedOutput []byte
}

func (so *captureOut) Write(p []byte) (n int, err error) {
	so.capturedOutput = append(so.capturedOutput, p...)

	errorMsgs := regexp.MustCompile(badMsgRegEx)
	if errorMsgs.Find(p) != nil {
		log.Fatalf("Detected that the Server encountered an issue. Log attached below:\n%s\n", p)
	}

	return os.Stdout.Write(p)
}

func SetVariables() {
	log.Println("Setting Environment Variables")

	setEnv("GAME_VERSION", "public")

	setEnv("BIND_IP", "0.0.0.0")
	writeToFile(configDir+"ip.txt", os.Getenv("BIND_IP"))

	log.Println("Environment Variables set!")
}

func ApplyPreInstallConfig() {
	log.Println("Applying PreInstall Config")

	gameVersion := os.Getenv("GAME_VERSION")
	replaceTextInFile(steamInstallFile, "beta .*", "beta "+gameVersion)

	log.Println("PreInstall Config set!")
}

func UpdateServer() {
	log.Println("Updating SteamCMD and Zomboid Dedicated Server")

	saveShellCmd("steamcmd.sh", "+runscript", steamInstallFile)

	log.Println("Update complete!")
}

func TestFirstRun() {
	log.Println("Testing First Run")

	go func() {
		duration, _ := time.ParseDuration(testInstallTimeout)
		time.Sleep(duration)

		processList, err := ps.Processes()
		if err != nil {
			log.Println("ps.Processes() Failed, are you using windows?")
			return
		}

		processName := regexp.MustCompile(serverProcessNameRegex)

		for x := range processList {
			process := processList[x]
			if processName.Find([]byte(process.Executable())) != nil {
				targetProcess, _ := os.FindProcess(process.Pid())

				log.Printf("Killing process [%d]\n", targetProcess.Pid)
				if err := targetProcess.Kill(); err != nil {
					log.Fatalf("Failed attempt to kill process [%d]. Exiting...\n", process.Pid)
				}
				break
			}
		}

	}()

	StartServer()

	log.Println("Test Run Complete!")
}

func ApplyPostInstallConfig() {
	log.Println("Applying PostInstall Config")

	log.Println("PostInstall Config Applied!")
}

func StartServer() {
	log.Println("Starting Server")

	saveShellCmd(serverFile,
		"-adminpassword", adminPass,
		"-adminusername", adminUser,
		"-cachedir="+configDir,
		"-ip", os.Getenv("BIND_IP"),
		"-port", steamPort,
		"-servername", serverName,
		"-steamvac", steamVac,
		"-udpport", rakNetPort,
		noSteam,
	)

	log.Println("Server Run Complete!")
}

// Util functions //

// setEnv Set an Environment Variable
func setEnv(key string, value string) {
	if preValue := os.Getenv(key); preValue != "" {
		log.Printf("Environment Variable [%s] already set to [%s]. Skipping...\n", key, preValue)
		return
	}

	if err := os.Setenv(key, value); err != nil {
		log.Fatalf("Failed to set Environment Variable [%s] with Value [%s]\n", key, value)
	}
}

func replaceTextInFile(fileName string, old string, new string) {
	if file, err := os.ReadFile(fileName); err != nil {
		log.Fatalf("Could not open File [%s] for editing. Error:\n%s\n", fileName, err)
	} else {
		re := regexp.MustCompile(old)
		outFile := re.ReplaceAllString(string(file), new)

		if err := os.WriteFile(fileName, []byte(outFile), 0444); err != nil {
			log.Fatalf("Could not write new content [%s] to file [%s]. Error:\n%s\n", outFile, fileName, err)
		}
	}
}

func writeToFile(fileName string, content string) {
	if err := os.WriteFile(fileName, []byte(content), 0444); err != nil {
		log.Fatalf("Could not write new content [%s] to file [%s]. Error:\n%s\n", content, fileName, err)
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

func getLocalIp() string {
	if addr, err := net.InterfaceAddrs(); err != nil {
		log.Fatalf("Could not retrieve Network Interface. Error:\n%s\n", err)
	} else {
		for _, addr := range addr {
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				// check if IPv4 or IPv6 is not nil
				if ipnet.IP.To4() != nil || ipnet.IP.To16 != nil {
					// print available addresses
					return ipnet.IP.String()
				}
			}
		}
	}

	return ""
}
