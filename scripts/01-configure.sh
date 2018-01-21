#! /bin/bash -ex

# Move the server artifact into the home directory
mv spigot-$SERVER_VERSION.jar /opt/minecraft/server.jar

# Make minecraft server bin
mkdir /opt/minecraft/bin

# Move s3 script
mv /tmp/s3_server_sync.py /opt/minecraft/bin
# Create EULA file
echo "eula=TRUE" > /opt/minecraft/eula.txt

# Create Server Start Script
cat << EOF > /opt/minecraft/bin/start.sh
#!/bin/bash -ex
cd /opt/minecraft

export BACKUP_DESTINATION=${S3_BUCKET}

/opt/minecraft/bin/s3_server_sync.py start
/usr/bin/java -Xmx3G -Xms3G -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=45 -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=50 -XX:G1MaxNewSizePercent=80 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1MixedGCLiveThresholdPercent=50 -XX:+AggressiveOpts -jar server.jar --noconsole
EOF

# Create Server Stop Script
cat << EOF > /opt/minecraft/bin/stop.sh
#!/bin/bash -x

export BACKUP_DESTINATION=${S3_BUCKET}

/usr/bin/mcrcon -H localhost -P 25575 -p ${SERVER_PASSWORD} "say This Server will shutdown now."
/usr/bin/mcrcon -H localhost -P 25575 -p ${SERVER_PASSWORD} stop
/opt/minecraft/bin/s3_server_sync.py stop
EOF

# Create Server Properties
cat << EOF > /opt/minecraft/server.properties
op-permission-level=4
allow-nether=true
level-name=world
enable-query=false
allow-flight=false
announce-player-achievements=true
server-port=25565
rcon.port=25575
query.port=25565
level-type=DEFAULT
enable-rcon=true
force-gamemode=false
level-seed=
server-ip=
max-tick-time=60000
max-build-height=256
spawn-npcs=true
white-list=false
spawn-animals=true
hardcore=false
snooper-enabled=true
texture-pack=
online-mode=true
resource-pack=
pvp=true
difficulty=1
enable-command-block=true
player-idle-timeout=0
gamemode=0
max-players=20
spawn-monsters=true
generate-structures=true
view-distance=10
spawn-protection=16
motd=Welcome to Virtual Zoos!
generator-settings=
rcon.password=${SERVER_PASSWORD}
max-world-size=29999984
EOF

# Make service user owner
chown -R minecraft:minecraft /opt/minecraft

# Make scripts executable
chmod +x /opt/minecraft/bin/*

# Create minecraft-server service
mv /tmp/minecraft-server.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable minecraft-server

# Create Server Check cron
mv /tmp/server_check.py /etc/cron.hourly/server_check
chmod +x /etc/cron.hourly/server_check
