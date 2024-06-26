local M = {}

M.ABILITY_LIST = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}

M.FULL_ABILITY_TO_ABRIVATION = {
	Strength = "STR",
	Dexterity = "DEX",
	Constitution = "CON",
	Intelligence = "INT",
	Wisdom = "WIS",
	Charisma = "CHA"
}

M.ABRIVATION_TO_FULL_ABILITY = {
	STR = "Strength",
	DEX = "Dexterity",
	CON = "Constitution",
	INT = "Intelligence",
	WIS = "Wisdom",
	CHA = "Charisma"
}

M.SR_LIST = {"1/8", "1/4", "1/2", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"}

M.SR_TO_NUMBER = {
	["1/8"]=0.125, ["1/4"]=0.25, ["1/2"]=0.5, ["1"]=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6,
	["7"]=7,["8"]=8, ["9"]=9, ["10"]=10, ["11"]=11, ["12"]=12, ["13"]=13, ["14"]=14, ["15"]=15
}

M.NUMBER_TO_SR = {
	[0.125]="1/8", [0.25]="1/4", [0.5]="1/2", [1]="1", [2]="2", [3]="3", [4]="4", [5]="5", [6]="6",
	[7]="7", [8]="8", [9]="9", [10]="10", [11]="11", [12]="12", [13]="13", [14]="14", [15]="15"
}


return M