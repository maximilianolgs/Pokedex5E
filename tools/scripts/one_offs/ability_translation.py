from pathlib import Path
import json

# https://github.com/PokeAPI/api-data

data_location = Path(__file__).parent.parent.parent.parent.parent / 'pokeapi-data' / 'data' 
localized_abilities_file = Path(__file__).parent.parent.parent.parent / 'assets' / 'localization' / 'abilities.json'
abilities_path = Path(__file__).parent.parent.parent.parent / 'p5e-data' / 'data'

localized_abilities = {}
abilities_list = {}
abilities_index = {}
aux = {}

# lang map
lang_map = {
            'en': 'en_us',
            'es': 'es_419',
            'fr': 'fr_fr',
            'de': 'de_de',
            'it': 'it_it'
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

# Open the localized abilities file
with open(localized_abilities_file, 'r', encoding='utf-8') as f:
    localized_abilities = json.load(f)

# Open the implemented abilities list
with open(abilities_path / 'abilities.json', 'r', encoding='utf-8') as f:
    abilities_list = json.load(f)

# Open the poke-data abilities index
with open(data_location / 'api' / 'v2' / 'ability' / 'index.json', 'r', encoding='utf-8') as f:
    aux = json.load(f)
    for item in aux['results']:
        abilities_index[item['name']] = item['url']
    aux = {}

# for each implemented ability
for key in abilities_list.keys():
    key = key.lower()
    # search for path on index and open ability file
    if key.lower().replace(' ', '-') in abilities_index:
        with open(str(data_location) + abilities_index[key.replace(' ', '-')] + 'index.json', 'r', encoding='utf-8') as f:
            aux = json.load(f)
        # get localized name
        for name in aux['names']:
            if name['language']['name'] == lang:
                # add localized name to localized_abilities
                localized_abilities[key][iso_lang] = name['name']
    else:
        if iso_lang not in localized_abilities[key]:
            localized_abilities[key][iso_lang] = 'NOT FOUND'
        else:
            print('[WARNING] "' + key + '" not found on ability index')
# dump json in localized_abilities_file
with open(localized_abilities_file, 'w', encoding='utf-8') as f:
    json.dump(localized_abilities, f, indent=2, ensure_ascii=False)

# clone abilities_file appending -iso_lang
print("\nDon't forget to clone p5e-data/data/abilities.json into p5e-data/data/abilities-" + iso_lang + ".json and translate the descriptions on the file")