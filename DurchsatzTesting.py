import time
from web3 import Web3
import matplotlib.pyplot as plt
from concurrent.futures import ThreadPoolExecutor

# Verbindung zum Sepolia-Netzwerk (Stellen Sie sicher, dass Sie die richtige RPC-URL haben)
w3 = Web3(
    Web3.HTTPProvider(
        "https://eth-sepolia.g.alchemy.com/v2/XQBNh8wjnqwj9QeDRBb7_SA4b3T17X6y"
    )
)

# Ihr Konto und privater Schlüssel
account_address = "0xEE20E04085C7de33cA0f1A4A7218867599238524"
private_key = "0xdda69d5ecde3950f97607598ee8fff65ae15ba09cb3350c240084df18616d99e"

# Adresse des Smart Contracts, mit dem Sie interagieren möchten
contract_address = "0x49684D88EC0c1b6017EB5065046772900870C8c5"
contract_abi = [
    {
        "inputs": [
            {"internalType": "uint256", "name": "parkingSpotId", "type": "uint256"}
        ],
        "name": "occupyParkingSpot",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [],
        "name": "releaseAllParkingSpots",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "parkingSpotId", "type": "uint256"}
        ],
        "name": "releaseParkingSpot",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function",
    },
    {"inputs": [], "stateMutability": "nonpayable", "type": "constructor"},
    {
        "inputs": [],
        "name": "EthInUSD",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "parkingSpotId", "type": "uint256"}
        ],
        "name": "getCurrentParkingFees",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [],
        "name": "getParkingSpotIds",
        "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "name": "parkingSpots",
        "outputs": [
            {"internalType": "bool", "name": "isOccupied", "type": "bool"},
            {
                "internalType": "uint256",
                "name": "occupancyStartTime",
                "type": "uint256",
            },
            {"internalType": "address", "name": "vehicleOwner", "type": "address"},
            {"internalType": "uint256", "name": "parkingFees", "type": "uint256"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
]  # ABI des Smart Contracts
start_nonce = w3.eth.get_transaction_count(account_address)
contract = w3.eth.contract(address=contract_address, abi=contract_abi)


def send_transaction(i):
    time.sleep(17)  # Fügt eine Verzögerung von 1 Sekunde hinzu
    # Erstellen Sie die Transaktionsdaten
    txn = contract.functions.occupyParkingSpot(i).build_transaction(
        {
            "chainId": 11155111,
            "gas": 200000,
            "gasPrice": w3.to_wei(
                str(20 + i), "gwei"
            ),  # Erhöht den Gaspreis für jede Transaktion
            "nonce": start_nonce + i - 1,  # Manuelle Nonce-Verwaltung
        }
    )

    # Signieren der Transaktion
    signed_txn = w3.eth.account.sign_transaction(txn, private_key)

    # Zeitstempel erfassen
    timestamp = time.time()

    # Senden der Transaktion
    txn_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
    print(f"Transaktion {i} von {account_address} gesendet mit Hash: {txn_hash.hex()}")
    print(f"Transaktion {i} abgeschickt um: {timestamp}")

    # Warten auf die Bestätigung der Transaktion und Drucken der Dauer
    receipt = w3.eth.wait_for_transaction_receipt(txn_hash)
    confirmation_time = time.time() - timestamp
    print(f"Transaktion {i} bestätigt nach {confirmation_time} Sekunden.")
    return confirmation_time


# Liste zum Speichern der Bestätigungszeiten
confirmation_times = []

# Verwenden Sie ThreadPoolExecutor, um alle Transaktionen gleichzeitig zu senden
with ThreadPoolExecutor() as executor:
    confirmation_times = list(executor.map(send_transaction, range(1, 11)))

# Diagramm erstellen
plt.plot(range(1, 11), confirmation_times)
plt.xlabel("Transaktionsnummer")
plt.ylabel("Bestätigungszeit (Sekunden)")
plt.title("Bestätigungszeiten für Transaktionen")
plt.show()
