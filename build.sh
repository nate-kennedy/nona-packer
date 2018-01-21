#! /bin/bash
set -e

# Set Build Vars
export VERSIONS_JSON=https://launchermeta.mojang.com/mc/game/version_manifest.json
export ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
echo "Checking version information."
case "X$VERSION" in
  X|XLATEST|Xlatest)
    export SERVER_VERSION=`curl -fsSL $VERSIONS_JSON | jq -r '.latest.release'`
  ;;
  XSNAPSHOT|Xsnapshot)
    export SERVER_VERSION=`curl -fsSL $VERSIONS_JSON | jq -r '.latest.snapshot'`
  ;;
  X[1-9]*)
    export SERVER_VERSION=$VERSION
  ;;
  *)
    export SERVER_VERSION=`curl -fsSL $VERSIONS_JSON | jq -r '.latest.release'`
  ;;
esac

# Determine if Image with server version already exists
IMAGES=$(aws ec2 describe-images --filter Name=tag:Version,Value=${SERVER_VERSION} --filter Name=tag:Application,Values=minecraft --query "Images[*].ImageId" --owner ${ACCOUNT_ID})
IMAGE_COUNT=$(echo ${IMAGES} | jq '. | length')
if [[ $IMAGE_COUNT -gt 0 ]]; then
  echo "Image with version $SERVER_VERSION aleardy exists."
  exit 0
fi

# Create the Image

echo "Creating image with version ${SERVER_VERSION}"
packer validate templates/server_aws_ebs_ami.json
packer build templates/server_aws_ebs_ami.json