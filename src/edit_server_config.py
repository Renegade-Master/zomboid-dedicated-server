#!/usr/bin/env python3

#
#  Project Zomboid Dedicated Server using SteamCMD Docker Image.
#  Copyright (C) 2021-2022 Renegade-Master [renegade.master.dev@protonmail.com]
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

"""
Author: Renegade-Master
Description:
    Script for editing the Project Zomboid Dedicated Server
    configuration file
"""

import sys
from configparser import RawConfigParser


def save_config(config: RawConfigParser, config_file: str) -> None:
    """
    Saves the server config file
    :param config: Dictionary of the values
    :param config_file: Path to the server config file
    :return: None
    """

    # Overwrite the file value with the new value
    with open(config_file, "w") as file:
        config.write(file, space_around_delimiters=False)


def load_config(config_file: str) -> RawConfigParser:
    """
    Loads the server config file
    :param config_file: Path to the server config file
    :return: ConfigParser Object containing the values
    """

    # Ensure that the file starts with a Section
    with open(config_file, "r+") as file:
        lines = file.readlines()
        if lines[0] != "[ServerConfig]\n":
            file.seek(0)
            file.write("[ServerConfig]\n")
            for line in lines:
                file.write(line)

    cp: RawConfigParser = RawConfigParser()
    cp.optionxform = lambda option: option

    if cp.read(config_file) is not None:
        return cp
    else:
        raise TypeError("Config file is invalid!")


def check_server_config_file(config_file: str) -> bool:
    """
    Checks if the server config file exists
    :param config_file: Path to the server config file
    :return: True if the file exists, False if not
    """

    try:
        with open(config_file, "r") as file:
            return True
    except FileNotFoundError:
        sys.stderr.write(f"{config_file} not found!\n")
        return False


if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: edit_server_config.py <config_file> <key> [<value>]")
        sys.exit(1)

    config_file: str = sys.argv[1]
    key: str = sys.argv[2]

    if check_server_config_file(config_file):
        config: RawConfigParser = load_config(config_file)

        if len(sys.argv) == 3:
            # Return the value of the given key
            if 'ServerConfig' in config:
                if key in config['ServerConfig']:
                    print(f"{config['ServerConfig'][key]}")
        else:
            # Assign a new value
            value: str = sys.argv[3]

            # Set the desired value
            config['ServerConfig'][key] = value

            # Save the config file
            save_config(config, config_file)
