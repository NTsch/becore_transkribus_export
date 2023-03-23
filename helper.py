import json

# Get all document IDs that exist for this collection
def extract_key_value(file_path, key):
    with open(file_path, 'r') as f:
        data = json.load(f)

    values = []
    extract_value(data, key, values)
    return values

def extract_value(obj, key, values):
    # Recursively search for values of key in nested objects
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == key:
                values.append(v)
            elif isinstance(v, (dict, list)):
                extract_value(v, key, values)
    elif isinstance(obj, list):
        for item in obj:
            extract_value(item, key, values)