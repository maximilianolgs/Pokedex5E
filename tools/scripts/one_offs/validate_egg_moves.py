from pathlib import Path
import json
import re

# https://github.com/PokeAPI/api-data

base_location = Path(__file__).parent.parent.parent.parent.parent / "pokeapi-data" / "data"
str_base_location = str(base_location.resolve())
input_location = Path(__file__).parent.parent.parent.parent.parent / "pokeapi-data" / "data" / "api" / "v2"
poke_location = Path(__file__).parent.parent.parent.parent / "p5e-data" / "data" / "pokemon"

pokemon_index_cap = 809
later_games = ["sword-shield", "brilliant-diamond-shining-pearl", "scarlet-violet", "ultra-sun-ultra-moon", "crystal", "gold-silver", "x-y"]
output_data = {}

lang = 'en'

def get_name(_json_data):
    _en_name = ""
    for _name in _json_data["names"]:
        if _name["language"]["name"] == "en":
            _en_name = _name["name"]
            break
    return _en_name

for index in range(pokemon_index_cap):
    index += 1
    
    egg_moves = []
    p5e_egg_moves = []
    
    json_path = input_location / "pokemon" / str(index) / "index.json"
    with json_path.open("r", encoding="utf-8") as f:
        json_data = json.load(f)
        moves = json_data["moves"]
        species = json_data["species"]["name"].capitalize()
     
    if species == "Farfetchd":
        species = "Farfetch'd"
    if species == "Mr-mime":
        species = "Mr. Mime"
    if species == "Mime-jr":
        species = "Mime Jr."
    if species == "Meowstic":
        species = "Meowstic-m"
    if species == "Type-null":
        species = "Type Null"
    if species == "Tapu-bulu":
        species = "Tapu Bulu"
    if species == "Tapu-fini":
        species = "Tapu Fini"
    if species == "Tapu-koko":
        species = "Tapu Koko"
    if species == "Tapu-lele":
        species = "Tapu Lele"
    
    for move in moves:
        vgd = move["version_group_details"]
        for mlm in vgd:
            if mlm["move_learn_method"]["name"] == "egg" and mlm["version_group"]["name"] not in later_games:
                json_path = Path(str_base_location + move["move"]["url"] + "index.json")
    
                with json_path.open("r", encoding="utf-8") as f:
                    json_data = json.load(f)
                    egg_moves.append(get_name(json_data))
                break
    
    # P5e data
    json_path = poke_location / (species + ".json")
    with json_path.open("r", encoding="utf-8") as f:
        json_data = json.load(f)
        if "egg" in json_data["Moves"]:
            p5e_egg_moves = json_data["Moves"]["egg"]

    missing = []
    for em in egg_moves:
        if em not in p5e_egg_moves:
            missing.append(em)
    if len(missing) > 0:
        output_data[species] = {}
        output_data[species]["Missing"] = missing
    
    extra = []
    for pm in p5e_egg_moves:
        if pm not in egg_moves:
            extra.append(pm)
    if len(extra) > 0:
        if species not in output_data:
            output_data[species] = {}
        output_data[species]["Extra"] = extra

print(output_data)
    
