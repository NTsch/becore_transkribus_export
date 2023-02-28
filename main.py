import requests
import os
import json

# Log in to Transkribus and get a session ID
login_url = 'https://transkribus.eu/TrpServer/rest/auth/login'
login_data = {'user': 'niklas.tscherne@uni-graz.at', 'pw': '35kv7q9u2GBnZ3F'}
response = requests.post(login_url, data=login_data)
session_id = response.headers['Set-Cookie'].split(';')[0]

# Set up the headers for subsequent requests
headers = {'Cookie': session_id}

# Get a list of collections
collections_url = 'https://transkribus.eu/TrpServer/rest/collections/list'
response = requests.get(collections_url, headers=headers)
collections = response.json()

# Create a directory to save the documents
if not os.path.exists('documents'):
    os.mkdir('documents')

# Save the list of collections
collections_file = 'documents/collections.json'
with open(collections_file, 'w', encoding='utf-8') as f:
    json.dump(response.json(), f, indent=4)

# Loop over each collection
for collection in collections:
    collection_id = collection['colId']
    collection_name = collection['colName']
    print(f'Processing collection {collection_name}')

    # Create a subdirectory for the collection
    collection_dir = os.path.join('documents', collection_name)
    if not os.path.exists(collection_dir):
        os.mkdir(collection_dir)

    # Get a list of documents for the collection and save it
    documents_url = f'https://transkribus.eu/TrpServer/rest/collections/{collection_id}/list'
    response = requests.get(documents_url, headers=headers)
    documents = response.json()
    
    documents_file = os.path.join(collection_dir, f'{collection_name}_collection.json')
    with open(documents_file, 'w', encoding='utf-8') as f:
        json.dump(response.json(), f, indent=4)

    # Loop over each document in the collection
    for document in documents:
        document_id = document['docId']
        document_name = document['title']

        # Retrieve the full document
        document_url = f'https://transkribus.eu/TrpServer/rest/collections/{collection_id}/{document_id}/fulldoc'
        response = requests.get(document_url, headers=headers)

        # Save the document to a file
        document_file = os.path.join(collection_dir, f'{document_name}.json')
        with open(document_file, 'w', encoding='utf-8') as f:
            json.dump(response.json(), f, indent=4)

print('All documents saved')