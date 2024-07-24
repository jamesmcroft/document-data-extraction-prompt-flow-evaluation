from promptflow import tool
from promptflow.connections import AzureOpenAIConnection
from openai import AzureOpenAI
from typing import List
from azure.identity import DefaultAzureCredential, get_bearer_token_provider


@tool
def extract_document_data(aoai_connection: AzureOpenAIConnection, model_deployment: str, system_prompt: str, extraction_prompt: str, temperature: float, top_p: float, image_uris: List[str]) -> str:
    """
    Extracts structured data from a document using the specified instruction and extraction prompts.

    :param aoai_connection: The Azure OpenAI connection to use for the extraction.
    :param model_deployment: The deployment ID of the model to use for extraction (e.g., "gpt-4o").
    :param system_prompt: The system prompt to use for the extraction.
    :param extraction_prompt: The extraction prompt to use for the extraction including the expected output format.
    :param temperature: The temperature to use for the extraction (e.g., 0.1 for deterministic outputs).
    :param top_p: The top_p value to use for the extraction (e.g., 0.1 for deterministic outputs).
    :param image_uris: A list of base64-encoded URIs for the document images to include in the extraction.

    :return: The extracted data.
    """

    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"
    )

    client = AzureOpenAI(
        api_version="2024-05-01-preview",
        azure_endpoint=aoai_connection.api_base,
        azure_ad_token_provider=token_provider
    )

    user_content = []

    user_content.append(
        {
            "type": "text",
            "text": extraction_prompt
        })

    for uri in image_uris:
        user_content.append(
            {
                "type": "image_url",
                "image_url": {
                    "url": uri
                }
            })

    response = client.chat.completions.create(
        model=model_deployment,
        messages=[
            {
                "role": "system",
                "content": system_prompt
            },
            {
                "role": "user",
                "content": user_content
            }
        ],
        temperature=temperature,
        top_p=top_p,
        max_tokens=4096
    )

    return response.choices[0].message.content
