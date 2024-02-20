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
	"encoding/json"
	"github.com/mitchellh/go-ps"
	log "github.com/sirupsen/logrus"
	"gopkg.in/ini.v1"
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
	testInstallTimeout = "30s"

	// Default configuration variables
	adminUser    = "superuser"
	adminPass    = "changeme"
	serverName   = "zomboid-server"
	steamPort    = "16261"
	rakNetPort   = "16262"
	steamVac     = "true"
	noSteam      = "-nosteam"
	gameVersion  = "public"
	rconPort     = "27015"
	rconPassword = "changeme_rcon"
	maxRam       = "8192m"
	gcConfig     = "ZGC"

	badMsgRegEx            = ".*(unknown option)|(Connection Startup Failed)|(expected IP address).*"
	serverProcessNameRegex = "ProjectZomboid6"
)

type zomboidJvmConfig struct {
	MainClass string   `json:"mainClass"`
	Classpath []string `json:"classpath"`
	VMArgs    []string `json:"vmArgs"`
}

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

func getLogLevel(name string) log.Level {
	var lvl log.Level

	switch name {
	case "DEBUG":
		lvl = log.DebugLevel
	case "INFO":
		lvl = log.InfoLevel
	case "Error":
		lvl = log.ErrorLevel
	default:
		lvl = log.InfoLevel
	}

	return lvl
}

func init() {
	if value, present := os.LookupEnv("LOG_LEVEL"); present {
		log.SetLevel(getLogLevel(value))
	} else {
		log.SetLevel(log.InfoLevel)
		log.Info("Log Level not supplied, or supplied incorrectly.")
	}
}

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

	writeToFile(configDir+"ip.txt", os.Getenv("BIND_IP"))

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

	go func() {
		duration, _ := time.ParseDuration(testInstallTimeout)
		time.Sleep(duration)

		processList, err := ps.Processes()
		if err != nil {
			log.Fatal("Call to ps.Processes() failed. Exiting...")
		}

		processName := regexp.MustCompile(serverProcessNameRegex)

		for x := range processList {
			process := processList[x]
			if processName.Find([]byte(process.Executable())) != nil {
				targetProcess, _ := os.FindProcess(process.Pid())

				log.Infof("Killing process [%d]\n", targetProcess.Pid)
				if err := targetProcess.Kill(); err != nil {
					log.Fatalf("Failed attempt to kill process [%d]. Exiting...\n", process.Pid)
				}
				break
			}
		}
	}()

	StartServer()

	log.Infoln("Test Run Complete!")
}

func ApplyPostInstallConfig() {
	log.Infoln("Applying PostInstall Config")
	serverConfigFile := configDir + "Server/" + os.Getenv("SERVER_NAME") + ".ini"
	jvmConfigFile := baseGameDir + "ProjectZomboid64.json"
	ini.PrettyFormat = false

	if cfg, err := ini.Load(serverConfigFile); err != nil {
		log.Fatalf("Could not open Server Config File [%s]. Error:\n%s\n", serverConfigFile, err)
	} else {
		cfg.Section("").Key("RCONPort").SetValue(os.Getenv("RCON_PORT"))
		cfg.Section("").Key("RCONPassword").SetValue(os.Getenv("RCON_PASSWORD"))

		if err := cfg.SaveTo(serverConfigFile); err != nil {
			log.Fatalf("Could not save changes to Server Config File [%s]. Error:\n%s\n", serverConfigFile, err)
		}
	}

	jvmConfig := map[*regexp.Regexp]string{
		regexp.MustCompile("-Xmx.*"):     "-Xmx" + os.Getenv("MAX_RAM"),
		regexp.MustCompile("-XX:+Use.*"): "-XX:+Use" + os.Getenv("GC_CONFIG"),
	}

	// Open the JSON Configuration file for editing
	if file, err := os.ReadFile(jvmConfigFile); err != nil {
		log.Fatalf("Could not open File [%s] for editing. Error:\n%s\n", jvmConfigFile, err)
	} else {
		var objMap zomboidJvmConfig

		if err := json.Unmarshal(file, &objMap); err != nil {
			log.Fatalf("Error encountered when Parsing JSON:\n%s\n", err)
		}

		// Iterate through the VM Args, and replace any ones that have been configured
		for idx, arg := range objMap.VMArgs {
			for regexString, replacement := range jvmConfig {
				if regexString.Match([]byte(arg)) {

					log.Debugf("Replacing [%s] with [%s]", arg, replacement)
					objMap.VMArgs[idx] = replacement
				}
			}
		}

		// Write the changed document back to the File
		if bytes, err := json.MarshalIndent(objMap, "", "    "); err != nil {
			log.Fatalf("Could not marshal new content [%s] to JSON structure. Error:\n%s\n", bytes, err)
		} else {
			if err := os.WriteFile(jvmConfigFile, bytes, 0444); err != nil {
				log.Fatalf("Could not write new content [%s] to file [%s]. Error:\n%s\n", bytes, jvmConfigFile, err)
			}
		}
	}

	log.Infoln("PostInstall Config Applied!")
}

func StartServer() {
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
}

// Util functions //

// setEnv Set an Environment Variable
func setEnv(key string, value string) {
	if preValue := os.Getenv(key); preValue != "" {
		log.Debugf("Operator set Environment Variable [%s] to [%s]. Skipping...\n", key, preValue)
		return
	}

	if err := os.Setenv(key, value); err != nil {
		log.Fatalf("Failed to set Environment Variable [%s] with Value [%s]\n", key, value)
	} else {
		log.Debugf("Setting Environment Variable [%s] to [%s].\n", key, value)
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

	log.Infof("Executing command: [%s]\n", myCmd)

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
