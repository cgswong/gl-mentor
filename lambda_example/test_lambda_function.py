import unittest
import json
import io
from unittest.mock import MagicMock, patch
from botocore.exceptions import ClientError
from PIL import Image

import lambda_function

class TestLambdaFunction(unittest.TestCase):

    def setUp(self):
        # Create a tiny dummy image for testing
        image = Image.new('RGB', (100, 100), color='red')
        self.image_buffer = io.BytesIO()
        image.save(self.image_buffer, format='JPEG')
        self.dummy_image_bytes = self.image_buffer.getvalue()

        self.mock_event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-bucket"},
                        "object": {"key": "test/image.jpg"}
                    }
                }
            ]
        }

    @patch('lambda_function.s3_client')
    def test_lambda_handler_success(self, mock_s3_client):
        # Mock S3 get_object
        mock_body = MagicMock()
        mock_body.read.return_value = self.dummy_image_bytes
        mock_s3_client.get_object.return_value = {
            "Body": mock_body,
            "ContentType": "image/jpeg"
        }

        # Mock S3 put_object to succeed
        mock_s3_client.put_object.return_value = {}

        response = lambda_function.lambda_handler(self.mock_event, None)

        # Assertions
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["message"], "Successfully processed all records.")
        self.assertEqual(len(body["processed"]), 1)
        self.assertEqual(body["processed"][0]["dest_key"], "resized-testimage.jpg")

        # Verify get_object called correctly
        mock_s3_client.get_object.assert_called_once_with(
            Bucket="test-bucket",
            Key="test/image.jpg"
        )
        
        # Verify put_object called correctly
        mock_s3_client.put_object.assert_called_once()
        put_kwargs = mock_s3_client.put_object.call_args[1]
        self.assertEqual(put_kwargs["Bucket"], "test-bucket-resized")
        self.assertEqual(put_kwargs["Key"], "resized-testimage.jpg")
        self.assertEqual(put_kwargs["ContentType"], "image/jpeg")

        # Verify resize behavior by parsing the uploaded buffer
        uploaded_bytes = put_kwargs["Body"]
        uploaded_image = Image.open(io.BytesIO(uploaded_bytes))
        self.assertEqual(uploaded_image.size, (50, 50))  # Half of 100x100

    @patch('lambda_function.s3_client')
    def test_lambda_handler_download_error(self, mock_s3_client):
        # Mock S3 get_object to throw error
        error_response = {'Error': {'Code': 'NoSuchKey', 'Message': 'The specified key does not exist.'}}
        mock_s3_client.get_object.side_effect = ClientError(error_response, 'GetObject')

        response = lambda_function.lambda_handler(self.mock_event, None)

        self.assertEqual(response["statusCode"], 207)
        body = json.loads(response["body"])
        self.assertEqual(len(body["failed"]), 1)
        self.assertIn("NoSuchKey", body["failed"][0]["error"])
        
    @patch('lambda_function.s3_client')
    def test_lambda_handler_invalid_image(self, mock_s3_client):
        # Mock S3 get_object to return garbage instead of an image
        mock_body = MagicMock()
        mock_body.read.return_value = b'This is not an image'
        mock_s3_client.get_object.return_value = {
            "Body": mock_body,
            "ContentType": "image/jpeg"
        }

        response = lambda_function.lambda_handler(self.mock_event, None)

        self.assertEqual(response["statusCode"], 207)
        body = json.loads(response["body"])
        self.assertEqual(len(body["failed"]), 1)
        self.assertIn("identif", body["failed"][0]["error"].lower()) # 'cannot identify image file'

    def test_resize_image(self):
        # Additional unit test for the resize logic standalone
        resized_bytes = lambda_function.resize_image(self.dummy_image_bytes)
        resized_img = Image.open(io.BytesIO(resized_bytes))
        self.assertEqual(resized_img.size, (50, 50))

if __name__ == '__main__':
    unittest.main()
