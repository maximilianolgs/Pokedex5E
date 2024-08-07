from pathlib import Path
import json
import os

root = Path(__file__).parent.parent.parent
datafiles = root / "assets" / "datafiles"
habitat_json = datafiles / "habitat.json"
poke_data = root / "p5e-data" / "data"
pokemon_folder = poke_data / "pokemon"
pokedex_extra_json = datafiles / "pokedex_extra.json"
moves_json = poke_data / "move_index.json"
tm_json = datafiles / "move_machines.json"
abilities_json = poke_data / "abilities.json"
feats_json = datafiles / "feats.json"

evolve_json = poke_data / "evolve.json"

images_path = datafiles.parent / "textures"


def iter_pokemon_names():
    for f in pokemon_folder.iterdir():
        if f.suffix == ".json":
            if "." not in f.name.replace(".json", ""):
                yield f.name.replace(".json", "")


def get_json(name):
    with (pokemon_folder / name).with_suffix(".json").open(encoding="utf8") as f:
        data = json.load(f)
    return data


def evolve():
    print("######### check_evolve #########")
    with open(evolve_json, "r") as f:
        evolve_data = json.load(f)
    pokemon_species = [x for x in iter_pokemon_names()]
    for species in iter_pokemon_names():
        #data = get_json(species)
        if species in evolve_data:
            if species in pokemon_species:
                pokemon_species.remove(species)
            data = evolve_data[species]
            current = data["current_stage"]
            total = data["total_stages"]
            if current == total:
                if "into" in data:
                    print("Last stage", species)
    
    print("Species not in evolve data")
    print(sorted(pokemon_species))

def pokedex_order():
    order = []
    indexes = []
    for species in iter_pokemon_names():
        pokemon_data = get_json(species)
        for species, data in pokemon_data.items():
            if data["index"] not in indexes:
                indexes.append(data["index"])
                order.append(species)
    return order


def habitat():
    print("######### check_habitat #########")
    with open(habitat_json, "r") as fp:
        habitat_data = json.load(fp)
    pokemon_species = [x for x in iter_pokemon_names()]
    for _, list_of_pokemon in habitat_data.items():
        for pokemon in list_of_pokemon:
            if pokemon in pokemon_species:
                pokemon_species.remove(pokemon)
    print("Not in habitat")
    print(sorted(pokemon_species))


def print_habitat():
    with open(habitat_json, "r") as fp:
        habitat_data = json.load(fp)
    for hab, list_of_pokemon in habitat_data.items():
        print(hab)
        for pokemon in list_of_pokemon:
            print(pokemon)
        print('\n\n\n')


def pokedex_extra():
    print("######### check_pokedex_extra #########")
    with open(pokedex_extra_json, "r", encoding="utf8") as fp:
        pokedex_extra_data = json.load(fp)
    for species in iter_pokemon_names():
        pokemon_data = get_json(species)
        try:
            pokedex_extra_data[str(pokemon_data["index"])]
        except:
            print("Pokedex: Can't find", species)


def moves():
    print("######### check_moves #########")
    for pokemon in iter_pokemon_names():
        data = get_json(pokemon)
        with open(moves_json, "r") as f:
            move_data = json.load(f)
            for move in data["Moves"]["Starting Moves"]:
                if move not in move_data:
                    print(pokemon, "Starting move: ", move, "Invalid")
            for level, moves in data["Moves"]["Level"].items():
                for move in moves:
                    if move not in move_data:
                        print(pokemon, "Level", level, "move: ", move, "Invalid")


def tm():
    print("######### check_tm #########")
    with open(tm_json, "r") as fp:
        with open(moves_json, "r") as f:
            move_data = json.load(f)
            tm_data = json.load(fp)

            for num, move in tm_data.items():
                if not move in move_data:
                    print("Can't find TM: ", num, move)


def abilities():
    print("######### check_abilities #########")
    for pokemon in iter_pokemon_names():
        data = get_json(pokemon)
        with open(abilities_json, "r") as f:
            ability_data = json.load(f)
            #for _, data in data.items():
            for ability in data["Abilities"]:
                if not ability in ability_data:
                    print("Can't find ability ", ability)
            if "Hidden Ability" in data and data["Hidden Ability"] not in ability_data:
                print("Can't find hidden ability ", data["Hidden Ability"])


def images():
    print("######### check_images #########")
    def check_image(_data, _sprite_suffix):
        _sprite_suffix = _sprite_suffix.replace(":","").replace(" ♀", "-f").replace(" ♂", "-m")
        _file_path = images_path / x / "{}{}.png".format(_data["index"], _sprite_suffix)
        if not os.path.exists(_file_path):
            print("Can't find image: ", "{}{}.png".format(_data["index"], p), "in", x)
        #else:
        #    print(f"Checked {_file_path.stem}")


    for p in iter_pokemon_names():
        data = get_json(p)
        for x in ["pokemons", "sprites"]:
            sprite_suffix = p
            if "variant_data" in data:
                sprite_suffix = data["variant_data"]["default"]
                if "sprite_suffix" in data["variant_data"]:
                    sprite_suffix = data["variant_data"]["sprite_suffix"]
                    check_image(data, sprite_suffix)
                elif "variants" in data["variant_data"]:
                    for variant in data["variant_data"]["variants"]:
                        sprite_suffix = data["variant_data"]["variants"][variant]["original_species"]
                        check_image(data, sprite_suffix)
                else:
                    check_image(data, sprite_suffix)
            else:
                check_image(data, sprite_suffix)


def long_vulnerabilities():
    for p in iter_pokemon_names():
        data = get_json(p)
        length = 0
        for t in ["Vul", "Res", "Imm"]:
            if t in data:
                length = max(length, len(", ".join(data[t])))
                print(length, p, ", ".join(data[t]))
    print(length)


def remove_vulnerabilities():
    for p in iter_pokemon_names():
        data = get_json(p)
        for t in ["Vul", "Res", "Imm"]:
            if t in data:
                del data[t]


def validate_all():
    images()
    abilities()
    moves()
    pokedex_extra()
    habitat()
    evolve()
    #tm()


def pokemon_list():
    index_list = {}
    for species in iter_pokemon_names():
        data = get_json(species)
        index = data["index"]
        if index > 0:
            if index not in index_list:
                index_list[index] = []
            index_list[index].append(species)

    with open(root / "index_order.json", "w") as fp:
        json.dump(index_list, fp)


def split():
    for species in iter_pokemon_names():
        data = get_json(species)
        species = species.replace(" ♀", "-f")
        species = species.replace(" ♂", "-m")

        with open(pokemon_folder / (species + ".json"), "w", encoding="utf8") as fp:
            json.dump(data, fp, indent="  ", ensure_ascii=False)

validate_all()
