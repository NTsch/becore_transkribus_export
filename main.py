import requests

# Define the API endpoint URL
login_url = 'https://transkribus.eu/TrpServer/rest/auth/login'
collection_url = 'https://transkribus.eu/TrpServer/rest/collections/list'

# Define the login credentials as a dictionary
data = {'user': 'niklas.tscherne@uni-graz.at', 'pw': '35kv7q9u2GBnZ3F'}

# Send a POST request with the login credentials
response = requests.post(login_url, data=data)

# Extract the session ID from the response headers
session_id = response.headers['Set-Cookie'].split(';')[0]

# Send a GET request to list the collections
headers = {'Cookie': session_id}
response = requests.get(collection_url, headers=headers)

# Print the response status code and content
print(response.status_code)
print(response.content)