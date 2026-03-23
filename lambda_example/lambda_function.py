import os
import logging
import json
import urllib.parse
import io
from typing import Any, Dict

import boto3
from botocore.exceptions import ClientError
from PIL import Image

# Structured logging configuration
logger = logging.getLogger()
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger.setLevel(log_level)

# Initialize S3 client outside of the handler for connection pooling
s3_client = boto3.client("s3")

def resize_image(image_bytes: bytes) -> bytes:
    """
    Resizes an image to half its dimensions.

    Args:
        image_bytes: The raw bytes of the source image.

    Returns:
        The raw bytes of the resized image.
    """
    try:
        with Image.open(io.BytesIO(image_bytes)) as image:
            # Calculate the new size (half the original dimensions)
            new_size = tuple(x // 2 for x in image.size)
            image.thumbnail(new_size)
            
            # Save the resized image to a new byte buffer
            output_buffer = io.BytesIO()
            # Preserve the original format, default to JPEG if format is unknown
            format_out = image.format if image.format else 'JPEG'
            image.save(output_buffer, format_out)
            
            logger.debug(f"Successfully resized image to {new_size}.")
            return output_buffer.getvalue()
    except Exception as e:
        logger.error(f"Failed to resize image: {str(e)}", exc_info=True)
        raise

def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    AWS Lambda handler to process S3 object creation events and resize images.

    Args:
        event: The event dictionary containing S3 event details.
        context: The Lambda execution context.

    Returns:
        A dictionary containing the status and results of the processing.
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    processed_records = []
    failed_records = []

    for record in event.get("Records", []):
        try:
            # Extract bucket and key information
            source_bucket = record["s3"]["bucket"]["name"]
            source_key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
            
            # Determine destination bucket and key
            dest_bucket = f"{source_bucket}-resized"
            
            # The original code replaced "/" with "" for the tmpkey.
            # We match that behavior to stay compatible with expected dest_key names.
            dest_key = f"resized-{source_key.replace('/', '')}"

            logger.info(f"Processing object s3://{source_bucket}/{source_key}")
            
            # Download the source image into memory
            try:
                response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
                image_bytes = response["Body"].read()
            except ClientError as e:
                logger.error(f"Error downloading object s3://{source_bucket}/{source_key}: {str(e)}", exc_info=True)
                raise
            
            # Resize the image in memory
            resized_image_bytes = resize_image(image_bytes)
            
            # Upload the resized image from memory to S3
            try:
                s3_client.put_object(
                    Bucket=dest_bucket,
                    Key=dest_key,
                    Body=resized_image_bytes,
                    ContentType=response.get("ContentType", "image/jpeg")
                )
            except ClientError as e:
                logger.error(f"Error uploading to object s3://{dest_bucket}/{dest_key}: {str(e)}", exc_info=True)
                raise

            logger.info(f"Successfully resized and uploaded to s3://{dest_bucket}/{dest_key}")
            processed_records.append({"source_key": source_key, "dest_key": dest_key})

        except Exception as e:
            logger.error(f"Failed processing record: {str(e)}", exc_info=True)
            # Log the specific failed record logic but keep going for the rest of the batch
            failed_records.append({"record": record, "error": str(e)})

    # Check for failures and report
    if failed_records:
        logger.warning(f"Batch completed with {len(failed_records)} errors.")
        return {
            "statusCode": 207,
            "body": json.dumps({
                "message": "Partial success",
                "processed": processed_records,
                "failed": failed_records
            })
        }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Successfully processed all records.",
            "processed": processed_records
        })
    }
