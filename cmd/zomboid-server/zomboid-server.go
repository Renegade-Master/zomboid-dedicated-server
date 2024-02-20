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

package main

import (
	log "github.com/sirupsen/logrus"
	server "renegade-master/zomboid-dedicated-server/internal"
)

func main() {
	log.Println("Initialising Renegade-Master: Project Zomboid Dedicated Server")
	server.SetVariables()

	server.ApplyPreInstallConfig()
	server.UpdateServer()
	server.TestFirstRun()
	server.ApplyPostInstallConfig()

	server.StartManagedServer()
}
