import requests
import os
import json
import subprocess
import argparse

# Log in to Transkribus and get a session ID
login_url = 'https://transkribus.eu/TrpServer/rest/auth/login'
login_data = {'user': 'niklas.tscherne@uni-graz.at', 'pw': '35kv7q9u2GBnZ3F'}
response = requests.post(login_url, data=login_data)
session_id = response.headers['Set-Cookie'].split(';')[0]

# Set up the headers for subsequent requests
headers = {'Cookie': session_id}

# Create a directory to save the documents
if not os.path.exists('documents'):
    os.mkdir('documents')

def get_everything():
    # Get a list of collections
    collections_url = 'https://transkribus.eu/TrpServer/rest/collections/list'
    response = requests.get(collections_url, headers=headers)
    collections = response.json()

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

def get_xml(collection_id: int, document_id: int, page_no: int):

    # Get the desired document as a JSON file
    doc_url = f'https://transkribus.eu/TrpServer/rest/collections/{collection_id}/{document_id}/fulldoc'
    response = requests.get(doc_url, headers=headers)
    doc_json = response.json()
    urls = []

    # Find the URLs for the PAGE-XML transcription files of the given page
    for page in doc_json['pageList']['pages']:
        if page['pageNr'] == int(page_no):
            for transcript in page['tsList']['transcripts']:
                urls.append(transcript['url'])
    
    # Download and save all XMLs
    for url in urls:
        response = requests.get(url)
        if response.status_code == 200:
            content = response.content
        
            with open(url.split('=')[1] + '.xml', 'wb') as f:
                f.write(content)
            
            print(f"File {url.split('=')[1]}.xml saved successfully.")
        else:
            print(f"Error downloading file from URL {url}.")

def get_transcription(collection_id: int, document_id: int):
    
    # Download the METS file for the desired document
    doc_url = f'https://transkribus.eu/TrpServer/rest/collections/{collection_id}/{document_id}/mets'
    response = requests.get(doc_url, headers=headers)
    mets_xml = response.text

    with open(f'mets_{collection_id}_{document_id}.xml', 'w') as f:
        f.write(mets_xml)
    
    # Transform PAGE to TEI via Saxon
    subprocess.call(['java', '-jar', 'SaxonHE11-5J/saxon-he-11.5.jar', '-xsl:page2tei/page2tei-0.xsl', f'-s:mets_{collection_id}_{document_id}.xml', f'-o:tk_tei_{collection_id}_{document_id}.xml'])
    subprocess.call(['java', '-jar', 'SaxonHE11-5J/saxon-he-11.5.jar', '-xsl:tk_tei2cei/tk_tei2cei.xsl', f'-s:tk_tei_{collection_id}_{document_id}.xml', f'-o:tk_cei_{collection_id}_{document_id}.xml'])

# Allowing running the desired function via argument
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='func_name')

parser_get_everything = subparsers.add_parser('get_everything')

parser_get_xml = subparsers.add_parser('get_xml')
parser_get_xml.add_argument('collection_id', nargs='?', default=87230)
parser_get_xml.add_argument('document_id', nargs='?', default=1002019)
parser_get_xml.add_argument('page_no')

parser_get_transcription = subparsers.add_parser('get_transcription')
parser_get_transcription.add_argument('collection_id', nargs='?', default=87230)
parser_get_transcription.add_argument('document_id', nargs='?', default=1002019)

args = parser.parse_args()

if args.func_name == "get_everything":
    get_everything()
elif args.func_name == "get_xml":
    get_xml(args.collection_id, args.document_id, args.page_no)
elif args.func_name == "get_transcription":
    get_transcription(args.collection_id, args.document_id)
