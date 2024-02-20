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

	rcon = "/usr/local/bin/rcon"
)
