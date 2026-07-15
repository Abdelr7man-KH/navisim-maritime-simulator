import socket
import json
import requests

# --- CONFIGURATION ---
UDP_IP = "0.0.0.0"  # 0.0.0.0 means "Listen to anyone on the Wi-Fi"
UDP_PORT = 5005     # The dedicated network port for our telemetry

# Unreal Engine API Setup
PRESET_NAME = "Control_Waterline"
BASE_URL = f"http://localhost:30010/remote/preset/{PRESET_NAME}/property"

PROPERTY_IDS = {
    "wind": "4754DF764FF62B9B2AF4B3965BB10B80",
    "amp": "EEAAA32340B02752E78AC6AFB6FAB917",
    "height": "C1480E7B41C23F8C3424DDA61547EB4C",
    "foam_p": "5D89E15744D671D7332BF98F89481AA5",
    "foam_d": "8B3BB9AF49D1A73AA6ADD4A5C25FF81E",
    "chop": "C43ED2BE40919AC551EE139DBAC65C1C"
}

WEATHER_PROFILES = {
    "1": {"name": "Calm",            "wind": 1.0,  "amp": 0.1,  "height": 1.0,  "foam_p": 0.0,  "foam_d": 5.0, "chop": 0.5},
    "2": {"name": "Light Breeze",    "wind": 3.0,  "amp": 0.2,  "height": 2.0,  "foam_p": 0.05, "foam_d": 4.0, "chop": 1.5},
    "3": {"name": "Gentle Breeze",   "wind": 5.0,  "amp": 0.3,  "height": 3.0,  "foam_p": 0.1,  "foam_d": 3.0, "chop": 2.5},
    "4": {"name": "Moderate Breeze", "wind": 8.0,  "amp": 0.4,  "height": 5.0,  "foam_p": 0.2,  "foam_d": 2.5, "chop": 4.0},
    "5": {"name": "Strong Breeze",   "wind": 12.0, "amp": 0.5,  "height": 8.0,  "foam_p": 0.4,  "foam_d": 2.0, "chop": 6.0},
    "6": {"name": "Gale",            "wind": 20.0, "amp": 0.8,  "height": 12.0, "foam_p": 0.6,  "foam_d": 1.5, "chop": 10.0},
    "7": {"name": "Strong Gale",     "wind": 30.0, "amp": 0.1,  "height": 15.0, "foam_p": 0.9,  "foam_d": 1.0, "chop": 15.0},
    "8": {"name": "Violent Storm",   "wind": 50.0, "amp": 0.05, "height": 20.0, "foam_p": 1.5,  "foam_d": 1.0, "chop": 25.0}
}

def set_water_property(property_key, value):
    prop_id = PROPERTY_IDS[property_key]
    url = f"{BASE_URL}/{prop_id}"
    try:
        requests.put(url, json={"PropertyValue": value})
    except requests.exceptions.ConnectionError:
        print(f"  ❌ Error: Could not reach Unreal Engine API for {property_key}.")

def process_weather_change(choice_id):
    if choice_id in WEATHER_PROFILES:
        profile = WEATHER_PROFILES[choice_id]
        print(f"\n🌊 Executing Weather Change: {profile['name']}")
        
        set_water_property("wind",   profile['wind'])
        set_water_property("amp",    profile['amp'])
        set_water_property("height", profile['height'])
        set_water_property("foam_p", profile['foam_p'])
        set_water_property("foam_d", profile['foam_d'])
        set_water_property("chop",   profile['chop'])
        print("✔ Telemetry injected into Engine.")
    else:
        print(f"⚠ Received unknown weather ID: {choice_id}")

# --- UDP LISTENING SERVER ---
def start_udp_server():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))
    
    print("="*50)
    print(f" 📡 SIMULATOR RECEIVER ONLINE (Listening on Port {UDP_PORT})")
    print("="*50)
    
    while True:
        # Wait for a UDP packet to arrive
        data, addr = sock.recvfrom(1024) 
        try:
            # Decode the JSON payload
            payload = json.loads(data.decode('utf-8'))
            weather_id = str(payload.get("weather_id"))
            
            print(f"\n📥 Received packet from {addr[0]}: {payload}")
            process_weather_change(weather_id)
            
        except json.JSONDecodeError:
            print("⚠ Received invalid JSON data.")

if __name__ == "__main__":
    start_udp_server()