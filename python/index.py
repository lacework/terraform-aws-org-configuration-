import boto3
import json
import logging
import os
import threading


def handler(event, context):
    timer = threading.Timer((context.get_remaining_time_in_millis() / 1000.00) - 0.5, timeout, args=[event, context])

    timer.start()

    print('Received event: %s' % json.dumps(event))

    try:
        src_bucket = os.environ['src_bucket']
        dst_bucket = os.environ['dst_bucket']
        prefix = os.environ['prefix']
        object = os.environ['object']

        copy_object(src_bucket, dst_bucket, prefix, object)

    except Exception as e:
        logging.error('Exception: %s' % e, exc_info=True)

    finally:
        timer.cancel()


def timeout(event, context):
    logging.error('Execution is timeout')


def copy_object(src_bucket: str, dst_bucket: str, prefix: str, object: str):
    s3 = boto3.client('s3')

    key = prefix + object
    copy_source = {
        'Bucket': src_bucket,
        'Key': key
    }

    print(f'copy_source: {copy_source}')
    print(f'dest_bucket: {dst_bucket}')
    print(f'key: {key}')

    s3.copy_object(CopySource=copy_source, Bucket=dst_bucket, Key=key)
