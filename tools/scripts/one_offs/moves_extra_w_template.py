import re
import os
import json

# Path to moves JSON files
move_path = '../../../p5e-data/data/moves'
moves_table_path = 'moves_table.json'
localized_move_names_path = '../../../assets/localization/moves.json'

# final json
file_data = {}
localized_move_names = {}

# lang map
lang_map = {
            "en": "en_us",
            "es": "es_419",
            "fr": "fr_fr",
            "de": "de_de",
            "it": "it_it",
            "ko-romanized": "ko-romanized"
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

fill_desc = input('populate description field? (y/n) ')
if fill_desc.lower() == 'y':
    fill_desc = True

# open move_table JSON file and load its contents
with open(moves_table_path, 'r', encoding='utf-8') as f:
    moves_table = json.load(f)

# open localized_move_names JSON file and load its contents
if os.path.isfile(localized_move_names_path):
    with open(localized_move_names_path, 'r', encoding='utf-8') as f:
        localized_move_names = json.load(f)

# go thru the files
for file in os.listdir(move_path):
    if file.endswith('.json'):
        # get the name of the file
        move_name = os.path.splitext(file)[0].lower()
        description = ''
        if fill_desc:
            with open(os.path.join(move_path, file), 'r', encoding='utf-8') as mf:
                file_content = json.load(mf)
                description = file_content.get('Description', 'NOT FOUND')
        # create the structure and add to list
        file_data[move_name] = {
                'name': moves_table[move_name][lang]['name'],
                'description': description
            }
        if not localized_move_names.get(move_name, False):
            localized_move_names[move_name] = {}
        
        localized_move_names[move_name][iso_lang] = moves_table[move_name][lang]['name']

output_filename = 'moves_extra-' + iso_lang + '.json'
with open(output_filename, 'w', encoding='utf-8') as f:
    json.dump(file_data, f, indent=4, ensure_ascii=False)

print(f'Data written on {output_filename}')

with open(localized_move_names_path, 'w', encoding='utf-8') as f:
    json.dump(localized_move_names, f, indent=4, ensure_ascii=False)

print(f'Data written on {localized_move_names_path}')