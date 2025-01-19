import json
import os
from pathlib import Path

def generate_abi():
    # Define the paths
    artifacts_dir = Path("out")
    output_dir = Path("abi")
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(exist_ok=True)
    
    # Walk through all contract artifacts
    for contract_file in artifacts_dir.rglob("*.json"):
        # Skip if not a main contract file (e.g., skip debug files)
        if ".dbg." in str(contract_file):
            continue
            
        # Read the contract artifact
        with open(contract_file, 'r') as f:
            contract_json = json.load(f)
            
        # Extract the ABI
        if 'abi' in contract_json:
            abi = contract_json['abi']
            
            # Create output filename
            contract_name = contract_file.stem  # Get filename without extension
            output_file = output_dir / f"{contract_name}.json"
            
            # Write ABI to file
            with open(output_file, 'w') as f:
                json.dump(abi, f, indent=2)
                
            print(f"Generated ABI for {contract_name}")

if __name__ == "__main__":
    generate_abi() 