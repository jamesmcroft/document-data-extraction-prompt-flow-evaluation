from promptflow import tool
import base64
from typing import List
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


@tool
def load_images(storage_account_name: str, image_container_name: str) -> List[str]:
    """
    Loads images from a specified Azure Blob Storage container and returns them as base64-encoded URIs.

    :param storage_account_name: The name of the Azure Storage account.
    :param image_container_name: The name of the container that stores the images.

    :return: A list of base64-encoded URIs for the images in the specified container.
    """

    account_url = f"https://{storage_account_name}.blob.core.windows.net"
    default_credential = DefaultAzureCredential()

    blob_service_client = BlobServiceClient(
        account_url, credential=default_credential)
    blob_container_client = blob_service_client.get_container_client(
        image_container_name)

    blob_list = blob_container_client.list_blobs()

    image_uris = []

    for blob in blob_list:
        blob_name = blob.name

        blob_client = blob_container_client.get_blob_client(blob_name)

        blob_properties = blob_client.get_blob_properties()
        content_type = blob_properties['content_settings'].content_type

        if content_type.startswith('image/'):
            try:
                blob_data = blob_client.download_blob().readall()

                base64_data = base64.b64encode(blob_data).decode('utf-8')
                image_uris.append(f"data:{content_type};base64,{base64_data}")
            except Exception as e:
                print(f"Error loading image {blob_name}: {e}")

    return image_uris
