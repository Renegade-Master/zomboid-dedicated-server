package internal

import (
	"log"
	"os"
	"regexp"
)

func SetVariables() {
	log.Println("Setting Environment Variables")

	setEnv("GAME_VERSION", "public")
}

func ApplyPreInstallConfig() {
	log.Println("Applying PreInstall Config")
	gameVersion := os.Getenv("GAME_VERSION")
	newText := "beta " + gameVersion

	replaceTextInFile("/home/steam/install_server.scmd", "beta .*", newText)
}

func ApplyPostInstallConfig() {
	log.Println("Applying PostInstall Config")
}

func UpdateServer() {
	log.Println("Updating Server")
}

func TestFirstRun() {
	log.Println("Testing First Run")
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
