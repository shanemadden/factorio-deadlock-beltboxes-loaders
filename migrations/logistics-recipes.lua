for _, force in pairs(game.forces) do
	force.reset_technologies()
	for tech_name, technology in pairs(force.technologies) do
		if technology.researched then
			for _, effect in pairs(technology.prototype.effects) do
				if effect.type == "unlock-recipe" then
					force.recipes[effect.recipe].enabled = true
				end
			end
		end
	end
end
