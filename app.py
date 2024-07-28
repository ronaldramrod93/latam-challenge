from helper import build_query, parse_to_json
from flask import Flask, request, jsonify
from google.cloud import pubsub_v1, bigquery
import os
import json

app = Flask(__name__)

# Initialize Pub/Sub client
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(os.getenv('GCP_PROJECT'), os.getenv('PUBSUB_TOPIC'))

# Initialize BigQuery client
bigquery_client = bigquery.Client()


@app.route('/challenge-latam-api/ingestData', methods=['POST'])
def ingest_data():
    data = request.get_json()
    # Publish message to topic
    future = publisher.publish(
        topic_path,
        json.dumps(data).encode('utf-8'))
    # Ensure the message is published
    future.result()
    return jsonify({"status": "Data published successfully"}), 200


@app.route('/challenge-latam-api/getData', methods=['GET'])
def get_data():
    query = build_query(
        "name, orders, revenue",
        os.getenv('GCP_PROJECT'),
        os.getenv('BQ_DATASET'),
        os.getenv('BQ_TABLE')
    )
    # Get data from Bigquery
    query_job = bigquery_client.query(query)
    results = query_job.result()
    # Parse results
    data = parse_to_json(results)
    # Return as JSON response
    return jsonify(data), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
