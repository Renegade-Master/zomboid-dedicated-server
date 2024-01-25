package internal

import (
	"log"
	"os"
	"os/exec"
	"regexp"
)

const (
	steamInstallFile = "/app/install_server.scmd"
	baseGameDir      = "/home/steam/ZomboidDedicatedServer/"
	serverFile       = baseGameDir + "start-server.sh"
)

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

	runShellCmd("timeout", serverFile)
}

func ApplyPostInstallConfig() {
	log.Println("Applying PostInstall Config")
}

func StartServer() {
	log.Println("Starting Server")
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
		re := regexp.MustCompile("beta .*")
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

	if err := myCmd.Run(); err != nil {
		log.Fatalf("Error executing command [%s]: [%s]\n", myCmd, err)
	}
}
