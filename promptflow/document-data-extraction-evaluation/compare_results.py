from promptflow import tool
from typing import Dict, Any


@tool
def compare_results(expected: Dict[str, Any], actual: Dict[str, Any]) -> Dict[str, Any]:
    """
    Compares the expected and actual results and returns the valid and invalid keys and the accuracy of the comparison.

    :param expected: The expected results.
    :param actual: The actual results.

    :return: The valid keys, invalid keys, and accuracy percentage of the comparison.
    """

    valid_keys = []
    invalid_keys = []

    def compare(expected_data, actual_data, parent_key=''):
        for key, value in expected_data.items():
            # Construct a unique key name using the parent key if available
            unique_key = f"{parent_key}.{key}" if parent_key else key

            if key in actual_data:
                if isinstance(value, dict):
                    compare(value, actual_data[key], unique_key)
                elif isinstance(value, list):
                    if isinstance(actual_data[key], list) and len(value) == len(actual_data[key]):
                        for i, item in enumerate(value):
                            compare(
                                {i: item}, {i: actual_data[key][i]}, unique_key)
                    else:
                        invalid_keys.append(unique_key)
                elif value == actual_data[key]:
                    valid_keys.append(unique_key)
                else:
                    invalid_keys.append(unique_key)
            else:
                invalid_keys.append(unique_key)

    compare(expected, actual)

    total_keys = len(valid_keys) + len(invalid_keys)
    accuracy = len(valid_keys) / total_keys if total_keys > 0 else 0

    return {
        "valid_keys": valid_keys,
        "invalid_keys": invalid_keys,
        "accuracy": accuracy
    }
