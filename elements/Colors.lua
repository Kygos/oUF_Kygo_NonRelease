local addonName, ns = ...


	-- Colors

	oUF.colors.power = {
		["MANA"] = {26/255, 160/255, 255/255},
		["RAGE"] = {255/255, 26/255, 48/255},
		["FOCUS"] = {255/255, 128/255, 64/255},
		["ENERGY"] = {255/255, 225/255, 26/255},
		["HAPPINESS"] = {0.00, 1.00, 1.00},
		["RUNES"] = {0.50, 0.50, 0.50},
		["RUNIC_POWER"] = {0.00, 0.82, 1.00},
		["AMMOSLOT"] = {0.80, 0.60, 0.00},
		["FUEL"] = {0.0, 0.55, 0.5},
		["HOLY_POWER"] = {0.96, 0.55, 0.73},
		["SOUL_SHARDS"] = {117/255, 82/255, 221/255},
	}

	oUF.colors.happiness = {
		[1] = {182/225, 34/255, 32/255},
		[2] = {220/225, 180/225, 52/225},
		[3] = {143/255, 194/255, 32/255},
	}

	oUF.colors.reaction = {
		[1] = {182/255, 34/255, 32/255},
		[2] = {182/255, 34/255, 32/255},
		[3] = {182/255, 92/255, 32/255},
		[4] = {220/225, 180/255, 52/255},
		[5] = {143/255, 194/255, 32/255},
		[6] = {143/255, 194/255, 32/255},
		[7] = {143/255, 194/255, 32/255},
		[8] = {143/255, 194/255, 32/255},
	}

	oUF.colors.smooth = {1, 0, 0, 1, 1, 0, 0.4, 0.4, 0.4} -- R -> Y -> W
	oUF.colors.smoothG = {1, 0, 0, 1, 1, 0, 0, 1, 0} -- R -> Y -> G
	oUF.colors.runes = {{196/255, 30/255, 58/255};{173/255, 217/255, 25/255};{35/255, 127/255, 255/255};{178/255, 53/255, 240/255};}


ns.Colors = Colors