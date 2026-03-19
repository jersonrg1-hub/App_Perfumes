import json

with open("credenciales.json", "r") as f:
    creds = json.load(f)

toml = f"""[gcp_service_account]
type = "{creds['type']}"
project_id = "{creds['project_id']}"
private_key_id = "{creds['private_key_id']}"
private_key = {json.dumps(creds['private_key'])}
client_email = "{creds['client_email']}"
client_id = "{creds['client_id']}"
token_uri = "{creds['token_uri']}"
"""

# Guarda el resultado en un archivo
with open("secrets.txt", "w") as f:
    f.write(toml)

print("✅ Archivo secrets.txt creado correctamente")