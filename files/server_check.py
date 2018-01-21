#!/usr/bin/env python

from mcstatus import MinecraftServer
import boto3
import sys
import time
import requests
import json
from subprocess import call

server = MinecraftServer.lookup("localhost:25565")
status = server.status()

# Wait for 10 mintues to stop. Exit if players are on server.
index = 0
while True:
    if status.players.online > 0:
        sys.exit(0)
    
    if index > 60:
        break
    
    time.sleep(10)
    index += 1


# Stop the server
call(['service', 'minecraft-server', 'stop'])

# Terminate the instance
r = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
instance_id = r._content
r = requests.get('http://169.254.169.254/latest/dynamic/instance-identity/document')
document = json.loads(r._content)
region = document['region']

session = boto3.session.Session(region_name=region)
ec2 = session.resource('ec2')
instance = ec2.Instance(instance_id)
instance.terminate()
