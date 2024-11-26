import requests
import os
import json
import subprocess
import argparse
from helper import extract_key_value
import xml.etree.ElementTree as ET

'''
script for extracting transcription data from Transkribus via its API
choice of getting the full .json data of everything available to a given user, the XML of a page, of a document, or of a collection
'''

# Log in to Transkribus and get a session ID
login_url = 'https://transkribus.eu/TrpServer/rest/auth/login'
with open('login_data.json', 'r') as file:
    json_data = json.load(file)
login_data = {
    'user': json_data['user'],
    'pw': json_data['pw']
}
response = requests.post(login_url, data=login_data)
session_id = response.headers['Set-Cookie'].split(';')[0]

# Set up the headers for subsequent requests
headers = {'Cookie': session_id}

# Create a directory to save the documents
if not os.path.exists('documents'):
    os.mkdir('documents')

def get_everything():
    # get the .json data for everything available to this user

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

    print('All documents saved.')

def upload_document(collection_id: int, file_path: str):
    # upload a document to Transkribus
    doc_url = f'https://transkribus.eu/TrpServer/rest/uploads?collId={collection_id}'
    response = requests.get(doc_url, headers=headers)
    print(response)

def get_xml(collection_id: int, document_id: int, page_no: int):
    # get the transcription of the given page from the given document from the given collection

    # Get the desired document as a JSON file
    doc_url = f'https://transkribus.eu/TrpServer/rest/collections/{collection_id}/{document_id}/fulldoc'
    response = requests.get(doc_url, headers=headers)
    doc_json = response.json()
    urls = []

    # Find the URLs for the PAGE-XML transcription files of the given page
    for page in doc_json['pageList']['pages']:
        if page_no is None or page['pageNr'] == int(page_no):
            for transcript in page['tsList']['transcripts']:
                urls.append(transcript['url'])
    
    # Download and save most recent XML
    latest_date = None
    latest_content = None
    latest_url = None

    for url in urls:
        response = requests.get(url)
        if response.status_code == 200:
            content = response.content
            xml_tree = ET.fromstring(content)
            last_change = xml_tree.find('.//{http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15}LastChange')
            lc_content = None
            if last_change is not None:
                lc_content = last_change.text
        
            if latest_date is None or (lc_content is not None and lc_content > latest_date):
                latest_date = lc_content
                latest_content = content
                latest_url = url
           
        else:
            print(f"Error downloading file from URL {url}.")
        
    if latest_content is not None:
        with open('transcriptions/pages/' + f'tk_page_{collection_id}_{document_id}_{page_no}.xml', 'wb') as f:
            f.write(latest_content)
        print(f"File tk_page_{collection_id}_{document_id}_{page_no}.xml saved successfully.")

def get_transcription_doc(collection_id: int, document_id: int):
    # get a document and convert it to TEI and CEI
    
    # Download the METS file for the desired document
    doc_url = f'https://transkribus.eu/TrpServer/rest/collections/{collection_id}/{document_id}/mets'
    response = requests.get(doc_url, headers=headers)
    mets_xml = response.text
    
    # Create the subfolders if they don't exist
    subfolders = ['mets', 'tei', 'cei']

    for subfolder in subfolders:
        subfolder_path = os.path.join('transcriptions', subfolder)
        if not os.path.exists(subfolder_path):
            os.makedirs(subfolder_path)

    with open(f'transcriptions/mets/mets_{collection_id}_{document_id}.xml', 'w') as f:
        f.write(mets_xml)
    
    # Transform PAGE first to TEI and then CEI via Saxon
    subprocess.call(['java', '-jar', 'SaxonHE11-5J/saxon-he-11.5.jar', '-xsl:page2tei/page2tei-0.xsl', f'-s:transcriptions/mets/mets_{collection_id}_{document_id}.xml', f'-o:transcriptions/tei/tk_tei_{collection_id}_{document_id}.xml'])
    subprocess.call(['java', '-jar', 'SaxonHE11-5J/saxon-he-11.5.jar', '-xsl:tk_tei2cei/tk_tei2cei.xsl', f'-s:transcriptions/tei/tk_tei_{collection_id}_{document_id}.xml', f'-o:transcriptions/cei/tk_cei_{collection_id}_{document_id}.xml'])

def get_all_transcriptions(collection_id: int):
    # use get_transcription_doc to get all transcriptions from all documents in the collection, as TEI and CEI

    file_path = 'documents/' + input("Enter the file path for the collection JSON, e.g. 'NACR - German charters/NACR - German charters_collection.json': ")
    key = 'docId'
    values = extract_key_value(file_path, key)
    
    # Run get_transcription_doc for every page of every ID  
    for doc_id in values:
            get_transcription_doc(collection_id, doc_id)

def get_pages_from_xml(file, collection_id:int):
    tree = ET.parse(file)
    root = tree.getroot()

    # Define the XML namespace for cei
    namespace = {"cei": "http://www.monasterium.net/NS/cei"}

    # Iterate over cei:sourceDesc elements
    for source_desc in root.findall(".//cei:sourceDesc", namespaces=namespace):
        # Extract the values of specific <cei:p> elements
        transkribus_id_element = source_desc.find(".//cei:p[@type='transkribus_id']", namespaces=namespace)
        transkribus_recto_element = source_desc.find(".//cei:p[@type='transkribus_recto']", namespaces=namespace)
        transkribus_verso_element = source_desc.find(".//cei:p[@type='transkribus_verso']", namespaces=namespace)

        # Check if the elements were found and have a text attribute
        if transkribus_id_element is not None:
            transkribus_id = transkribus_id_element.text
        else:
            transkribus_id = None

        if transkribus_recto_element is not None:
            transkribus_recto = transkribus_recto_element.text
            get_xml(collection_id, int(transkribus_id), int(transkribus_recto))
        else:
            transkribus_recto = None

        if transkribus_verso_element is not None:
            transkribus_verso = transkribus_verso_element.text
            get_xml(collection_id, int(transkribus_id), int(transkribus_verso))
        else:
            transkribus_verso = None

# Allowing running the desired function via argument
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='func_name')

parser_get_everything = subparsers.add_parser('get_everything')

parser_get_xml = subparsers.add_parser('get_xml')
parser_get_xml.add_argument('collection_id', nargs='?', default=87230)
parser_get_xml.add_argument('document_id', nargs='?', default=1002019)
parser_get_xml.add_argument('page_no', nargs='?')

parser_get_transcription_doc = subparsers.add_parser('get_transcription_doc')
parser_get_transcription_doc.add_argument('collection_id', nargs='?', default=87230)
parser_get_transcription_doc.add_argument('document_id', nargs='?', default=1002019)

parser_get_all_transcriptions = subparsers.add_parser('get_all_transcriptions')
parser_get_all_transcriptions.add_argument('collection_id', nargs='?', default=44923)

parser_get_pages_from_xml = subparsers.add_parser('get_pages_from_xml')
parser_get_pages_from_xml.add_argument('file', nargs='?', default='../cluny_spreadsheet/cluny_spreadsheet2CEI.xml')
parser_get_pages_from_xml.add_argument('collection_id', nargs='?', default=44923)

parser_upload_document = subparsers.add_parser('upload_document')
parser_upload_document.add_argument('collection_id', nargs='?', default=183812)
parser_upload_document.add_argument('file_path', nargs='?', default='')

args = parser.parse_args()

if args.func_name == "get_everything":
    get_everything()
elif args.func_name == "get_xml":
    get_xml(args.collection_id, args.document_id, args.page_no)
elif args.func_name == "get_transcription_doc":
    get_transcription_doc(args.collection_id, args.document_id)
elif args.func_name == "get_all_transcriptions":
    get_all_transcriptions(args.collection_id)
elif args.func_name == "get_pages_from_xml":
    get_pages_from_xml(args.file, args.collection_id)
elif args.func_name == "upload_document":
    upload_document(args.collection_id, args.file_path)