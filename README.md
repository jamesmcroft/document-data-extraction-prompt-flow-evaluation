# Document Data Extraction with GPT-4o and Evaluation using Prompt Flow

This sample demonstrates [how to use GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#gpt-4o-and-gpt-4-turbo) to extract structured JSON data from PDF documents and evaluate the extracted data using the [Prompt Flow](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/flow-bulk-test-evaluation) feature in Azure AI Studio.

The approach builds on the understanding that [Azure OpenAI GPT-4o is effective at analyzing document images and extracting structured JSON objects](https://github.com/Azure-Samples/azure-openai-gpt-4-vision-pdf-extraction-sample) from them based on a provided extraction prompt including an expected output schema. The approach for evaluating document data extraction with Prompt Flow in Azure AI Studio highlights the following advantages:

- **Automated evaluation**: Custom Prompt Flow evaluations allow you to create an automated run which can evaluate multiple test cases in parallel, providing a comprehensive report and analysis of all the results in one place.
- **Prompt engineering testing**: Similar to creating traditional test cases for code, you can create various extraction prompt scenarios to evaluate changes in the prompt's performance. This can include variations on the schema, GPT model parameters, and the rules for extracting data.
- **Simplicity**: The approach using Prompt Flow narrows the scope of data extraction evaluation to discrete tasks in your AI application's workflow, making it easier to evaluate and improve the performance of your extraction prompts in a controlled environment before integrating the changes into your application.

The provided [Sample notebook](./Sample.ipynb) provides all the necessary steps to deploy the infrastructure and run the sample in your Azure subscription. It provides a dedicated learning environment for you to understand how to use GPT-4o for document data extraction and evaluate the extracted data using Prompt Flow in Azure AI Studio.

> [!IMPORTANT]
> Running the evaluation prompt flow for each test case with GPT-4o accrues token-based charges as would be expected running this in application code. Images are converted into tokens by converting your high resolution images into separate 512px tiled images. For more information, see the [Azure OpenAI image token overview](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview#image-tokens-gpt-4-turbo-with-vision).

## Getting Started

### Prerequisites

The sample repository comes with a [**Dev Container**](https://code.visualstudio.com/docs/remote/containers) that contains all the necessary tools and dependencies to run the sample. To use the Dev Container, you need to have the following tools installed on your local machine:

- Install [**Visual Studio Code**](https://code.visualstudio.com/download)
- Install [**Docker Desktop**](https://www.docker.com/products/docker-desktop)
- Install [**Remote - Containers**](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for Visual Studio Code

### Run the sample notebook

Before running the notebook, open the project in Visual Studio Code and start the Dev Container. This will ensure that all the necessary dependencies are installed and the environment is ready to run the notebook.

Once the Dev Container is running, open the [**Sample.ipynb**](./Sample.ipynb) notebook and follow the instructions in the notebook to run the sample.

> [!NOTE]
> The sample will guide you through the process of deploying the necessary infrastructure, deploying the Prompt Flows to the Azure AI Studio, and finally running the evaluation for the document data extraction.

### Clean up resources

After you have finished running the sample, you can clean up the resources using the following steps:

1. Run the `az group delete` command to delete the resource group and all the resources within it.

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

The `<resource-group-name>` is the name of the resource group that can be found in the **resourceGroupInfo** JSON object in the [**EnvironmentOutputs.json**](./EnvironmentOutputs.json) file created after running the Sample notebook.