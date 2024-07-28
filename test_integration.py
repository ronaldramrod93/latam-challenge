import os
import requests

# Get the URL of the deployed service from environment variable
CLOUD_RUN_URL = os.getenv('CLOUD_RUN_URL')


def test_get_data():
    # Endpoint URL
    url = f"{CLOUD_RUN_URL}/challenge-latam-api/getData"

    # Send GET request to the endpoint
    response = requests.get(url)

    # Check if the request was successful
    assert response.status_code == 200

    # Parse the response data
    data = response.json()

    # Ensure the response is a list
    assert isinstance(data, list)

    # Ensure the list is not empty
    assert len(data) > 0

    # Check the required structure of the data
    expected_keys = ["name", "orders", "revenue"]
    for item in data:
        assert all(key in item for key in expected_keys)
