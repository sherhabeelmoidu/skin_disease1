import requests

url = "https://model-1-1.onrender.com/"
files = {'file': ('test.jpg', b'fake image data', 'image/jpeg')}
try:
    response = requests.post(url, files=files)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text[:500]}")
except Exception as e:
    print(f"Error: {e}")
