# nona-packer

[![Build Status](https://travis-ci.org/nate-kennedy/nona-packer.svg?branch=master)](https://travis-ci.org/nate-kennedy/nona-packer)

## What is this?
This repo contains a packer template for building an immutable minecraft AMI. 
There are several build scripts in here which will ensure that you can take this
repo and easily build an image on your CI/CD tool. Personally, I am running this
as a daily job through travis.

## Features
### Build
* Automatically find latest packer version and install
* Automatically find latest Spigot (Customized minecraft server) version
* Minimal configuration required

### AMI
* Auto Starts Minecraft on boot.
* Backs up server data to S3
* Self Terminates when inactive

## S3 Backups
This image is launched with an hourly cron task that polls the server for player
count. If there are no players when the tasks runs then the server will terminate.
My intention is to not have any EC2/EBS resources when players are offline. S3 
storage is cheaper than EBS so world data is persisted there instead.

S3 storage is facilitated through the [s3_server_sync](files/s3_server_sync.py) 
script. When the minecraft service starts it will fetch the last backup from S3.
When the service stops it will archive the world directories and push them to 
S3.

AWS credentials are not passed into this script. You must launch this image with
an IAM role that allows access to S3.

## Packer Job
As mentioned above, this job requires minimal configuration. When run with the 
[build script](build.sh) only two environment variables must be set by the user:
* `SERVER_PASSWORD` the RCON password. RCON is used for perform administrative actions on the server
* `S3_BUCKET` the bucket where backups will be pushed to

## TODOs
* Make the server properties more configurable. Right now the minecraft server itself is very minimally configured. I'd like to make the following part of the build:
    * Set a login password
    * Whitelist players
    * Install bukkit plugins
* AMI and S3 management. There is currently no method for cleaning up the AMIs and S3 backup. The cost is small but will ballon over time if unmanaged.
* Better documentation/tutorial

## See It in action
Check out the build on travis: [nona-packer](https://travis-ci.org/nate-kennedy/nona-packer)