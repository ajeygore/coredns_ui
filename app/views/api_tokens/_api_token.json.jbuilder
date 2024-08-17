json.extract! api_token, :id, :token, :user_id, :expires_at, :created_at, :updated_at
json.url api_token_url(api_token, format: :json)
