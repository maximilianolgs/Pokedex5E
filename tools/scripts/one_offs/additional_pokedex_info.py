from pathlib import Path
import json
import re

# https://github.com/PokeAPI/api-data

input_location = Path(__file__).parent.parent.parent.parent.parent / "pokeapi-data" / "data" / "api" / "v2"
output_location = Path(__file__).parent.parent.parent.parent / "assets" / "datafiles"

output_data = {}
pokemon_index_cap = 809

lang_map = {
            "en": ".json",
            "es": "-es_419.json",
            "fr": "-fr_fr.json",
            "de": "-de_de.json",
            "it": "-it_it.json"
            }

lang = input('Input target lang: ')
lang = lang.lower()
iso_lang = lang_map.get(lang, False)
if not iso_lang:
    print('invalid lang.')
    print('next time input one of the following valid languages:')
    for key, value in lang_map.items():
        print(key)
    raise SystemExit()

def get(_json_data, version):
    _flavor_text = ""
    for _flavor in _json_data["flavor_text_entries"]:
        if _flavor["language"]["name"] == lang and (
                _flavor["version"]["name"] == version):
            _flavor_text = _flavor["flavor_text"].replace(species.upper(), species.capitalize()).replace("\n",
                                                                                                       " ").replace(
                "\x0c", " ").replace("POKéMON", "Pokémon").replace("“", '\"').replace("”", '\"')
            break
    return _flavor_text

for index in range(pokemon_index_cap):
    index += 1

    json_path = input_location / "pokemon" / str(index) / "index.json"
    with json_path.open("r", encoding="utf-8") as f:
        json_data = json.load(f)
        weight_text = json_data["weight"]
        height_text = json_data["height"]
        species = json_data["name"].capitalize()

    json_path = input_location / "pokemon-species" / str(index) / "index.json"
    with json_path.open("r", encoding="utf-8") as f:
        json_data = json.load(f)

        # Prefer omega-ruby
        flavor_text = get(json_data, "omega-ruby")

        # Try Sun
        if not flavor_text:
            flavor_text = get(json_data, "sun")

        # Try ultra-sun
        if not flavor_text:
            flavor_text = get(json_data, "ultra-sun")

        # Try Shield
        if not flavor_text:
            flavor_text = get(json_data, "shield")

        # Try Sword
        if not flavor_text:
            flavor_text = get(json_data, "sword")

        for genus in json_data["genera"]:
            if genus["language"]["name"] == lang:
                genus_text = genus["genus"]
                break
    output_data[index] = {"flavor": flavor_text, "height": height_text, "weight": weight_text, "genus": genus_text}

with open(output_location / ("pokedex_extra" + iso_lang), "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent="  ", ensure_ascii=False)
