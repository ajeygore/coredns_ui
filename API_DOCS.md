# CoreDNS UI API Documentation

## Base URL
`/api/v1/zones`

## Authentication
All API endpoints require an API token to be passed in the `Authorization` header.

**Headers:**
```http
Authorization: <api_token>
Content-Type: application/json
```

---

## Endpoints

### 1. Create Subdomain
Creates a new subdomain zone along with default A records (`@` and `*`) pointing to the provided IP address.

* **URL:** `/create_subdomain`
* **Method:** `POST`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the subdomain (e.g., `sub.example.com`).
  * `zone[data]` (string, required): The target IP address for the subdomain.
* **Success Response:**
  * **Code:** 201 Created
  * **Content:** `{ "id": 1, "name": "sub.example.com" }`
* **Error Response:**
  * **Code:** 422 Unprocessable Entity
  * **Content:** `{ "errors": ["..."] }`
  * **Code:** 401 Unauthorized (if API token is invalid)

### 2. Delete Subdomain
Deletes an existing subdomain zone and all its associated records.

* **URL:** `/delete_subdomain`
* **Method:** `DELETE`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the subdomain to delete.
* **Success Response:**
  * **Code:** 200 OK
  * **Content:** `{ "name": "sub.example.com" }`

### 3. Create ACME Challenge
Creates an `_acme-challenge` TXT record for the specified zone, typically used for SSL/TLS certificate validation.

* **URL:** `/create_acme_challenge`
* **Method:** `POST`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the zone.
  * `zone[data]` (string, required): The challenge data for the TXT record.
* **Success Response:**
  * **Code:** 201 Created
  * **Content:** `{ "id": 2, "name": "_acme-challenge", "data": "challenge_token_data" }`

### 4. Delete ACME Challenge
Deletes the `_acme-challenge` TXT record for the specified zone.

* **URL:** `/delete_acme_challenge`
* **Method:** `DELETE`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the zone.
* **Success Response:**
  * **Code:** 200 OK
  * **Content:** `{ "id": 2, "name": "_acme-challenge", "data": "challenge_token_data" }`

### 5. Add A Record
Adds or updates an A record in the specified zone.

* **URL:** `/add_a`
* **Method:** `POST`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the zone.
  * `zone[data]` (string, required): A comma-separated string containing the record name and IP address (e.g., `"www,10.1.1.2"`).
* **Success Response:**
  * **Code:** 201 Created
  * **Content:** `{ "id": 3, "name": "www", "data": "10.1.1.2" }`

### 6. Add MX Record
Adds an MX record to the specified zone.

* **URL:** `/add_mx`
* **Method:** `POST`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the zone.
  * `mx[priority]` (integer, required): The priority of the MX record (e.g., `10`).
  * `mx[host]` (string, required): The mail server hostname (e.g., `mail.example.com`).
  * `mx[record_name]` (string, optional): The name for the record. Defaults to `@` if not provided.
  * `mx[ttl]` (integer, optional): The Time-To-Live for the record. Defaults to `300`.
* **Success Response:**
  * **Code:** 201 Created
  * **Content:** `{ "id": 4, "name": "@", "data": "10 mail.example.com", "priority": "10", "host": "mail.example.com", "ttl": 300 }`
* **Error Response:**
  * **Code:** 404 Not Found
  * **Content:** `{ "errors": ["Zone not found"] }`

### 7. Delete MX Record
Deletes an MX record from the specified zone.

* **URL:** `/delete_mx`
* **Method:** `DELETE`
* **Body Parameters:**
  * `zone[name]` (string, required): The name of the zone.
  * `mx[priority]` (integer, required): The priority of the MX record to delete.
  * `mx[host]` (string, required): The mail server hostname to delete.
  * `mx[record_name]` (string, optional): The name for the record. Defaults to `@` if not provided.
* **Success Response:**
  * **Code:** 200 OK
  * **Content:** `{ "id": 4, "name": "@", "data": "10 mail.example.com", "priority": "10", "host": "mail.example.com" }`
* **Error Response:**
  * **Code:** 404 Not Found
  * **Content:** `{ "errors": ["Zone not found"] }` or `{ "errors": ["MX record not found"] }`
