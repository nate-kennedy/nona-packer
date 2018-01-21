#!/usr/bin/env bats

@test "Server Jar is baked in" {
  [ -e /opt/minecraft/server.jar ]
}

@test "Minecraft service is loaded" {
    run bash -c "systemctl --all list-units minecraft* | grep minecraft-server"
}

@test "Dynamic Files Exist" {
    [ -e /opt/minecraft/eula.txt ]
    [ -e /opt/minecraft/bin/start.sh ]
    [ -e /opt/minecraft/server.properties ]
    [ -e /opt/minecraft/bin/stop.sh ]
}

@test "Terminate Cron exists" {
    [ -e /etc/cron.hourly/server_check ]
}
