from pathlib import Path
import configparser

game_project_file = Path(__file__).parent.parent.parent / 'game.project'
build_config_file = Path(__file__).parent.parent.parent / 'build.cfg'

live_config = configparser.ConfigParser()
build_config = configparser.ConfigParser()

live_config.read(game_project_file)
build_config.read(build_config_file)

has_production_values = False

for section in build_config:
    print('[' + section + ']')
    for prop in build_config[section]:
        if live_config[section][prop] == build_config[section][prop]:
            has_production_values = True
            print(prop + ' = PRODUCTION')
        else:
            print(prop + ' = DEVELOP')

print()
if has_production_values:
    print('live configuration has production values')
else:
    print('live configuration has development values')

op = 'x'
while op != 'y' and op != 'n':
    op = input('change values? (y/n): ')
    op = op.lower()

if op == 'n':
    print('bye!')
    raise SystemExit()

for section in build_config:
    for prop in build_config[section]:
        if has_production_values:
            live_config[section][prop] = ''
        else:
            live_config[section][prop] = build_config[section][prop]

with open(game_project_file, 'w') as configfile:
    live_config.write(configfile)

