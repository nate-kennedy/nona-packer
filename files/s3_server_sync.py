#!/usr/bin/env python

import boto3
import botocore
import os
import zipfile
import time
import sys
import logging

logger = logging.getLogger('server_sync')
hdlr = logging.FileHandler('/var/tmp/server_sync.log')
formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
hdlr.setFormatter(formatter)
logger.addHandler(hdlr) 

s3_bucket = os.environ['BACKUP_DESTINATION']
s3 = boto3.resource('s3')

def zipdir(path, ziph):

    for root, dirs, files in os.walk(path):
        for file in files:
            ziph.write(os.path.join(root, file),
                       os.path.relpath(os.path.join(root, file),
                                       os.path.join(path, '..')))


def zipit(dir_list, zip_name):
    zipf = zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED)
    for dir in dir_list:
        zipdir(dir, zipf)
    zipf.close()

def teardown():
    # Get the list of world directories
    logger.info('Started tear down')
    world_list = ['/opt/minecraft/{}'.format(dir) for dir in next(os.walk('/opt/minecraft'))[1] if 'world' in dir]
    logger.info('World list is: {}'.format(world_list))

    # Zip the directories
    backup_name = 'world_backup_{}.zip'.format(int(time.time()))
    backup_local_path = '/tmp/{}'.format(backup_name)
    zipit(world_list, backup_local_path)

    # Upload to S3
    backup_remote_path = 'backup/{}'.format(backup_name)
    s3.meta.client.upload_file(backup_local_path, s3_bucket, backup_remote_path)
    s3.meta.client.upload_file(backup_local_path, s3_bucket, 'backup/latest.zip')
    logger.info('Backed up to s3')

def spinup():
    logger.info('Starting spin up')
    # Get 'latest' backup 
    try:
        s3.Bucket(s3_bucket).download_file('backup/latest.zip', '/tmp/latest.zip')
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            return
        else:
            raise
    logger.info('Downloaded latest server archive')
    zip_ref = zipfile.ZipFile('/tmp/latest.zip', 'r')
    zip_ref.extractall('/opt/minecraft')
    zip_ref.close()
    logger.info('Extracted file to minecraft home')

if __name__ == '__main__':
    if sys.argv[1] == 'start':
        spinup()
    elif sys.argv[1] == 'stop':
        teardown()
