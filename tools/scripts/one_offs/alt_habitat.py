from pathlib import Path
import json
import re

# https://github.com/PokeAPI/api-data

input_location = Path(__file__).parent.parent.parent.parent.parent / "pokeapi-data" / "data" / "api" / "v2"
output_location = Path(__file__).parent.parent.parent.parent / "assets" / "datafiles"

output_data = {}
pokemon_index_cap = 809

habitat_map = {
            "cave": "Cave",
            "forest": "Forest",
            "grassland": "Grass",
            "mountain": "Mountain",
            "rough-terrain": "Rugged",
            "sea": "Sea",
            "urban": "Urban",
            "waters-edge": "Water's Edge",
            "arctic": "Arctic",
            "rare": "Rare"
            }

for index in range(pokemon_index_cap):
    index += 1

    json_path = input_location / "pokemon-species" / str(index) / "index.json"
    with json_path.open("r", encoding="utf-8") as f:
        json_data = json.load(f)
    
    species = json_data["name"].capitalize()
    if not json_data.get("habitat") or not json_data["habitat"].get("name"):
        habitat = "None"
    else:
        habitat = json_data["habitat"]["name"]
        habitat = habitat_map[habitat]
    
    if not output_data.get(habitat):
        output_data[habitat] = []
    
    output_data[habitat].append(species)

with open(output_location / "alt_habitat", "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent="  ", ensure_ascii=False)
