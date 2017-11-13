function RPaladinDamage() 
	className, class = UnitClass("player")
	if class=="PALADIN" then
		DEFAULT_CHAT_FRAME:AddMessage("RPaladinDamage loaded.", 0.26, 0.97, 0.26);
		SLASH_RPALADINDAMAGE1 = "/rpaladindamage";
		SLASH_RPALADINDAMAGE2 = "/rpd";
		SlashCmdList["RPALADINDAMAGE"] = CalculatePaladinDamage;
	else
		DEFAULT_CHAT_FRAME:AddMessage("RPaladinDamage disabled, you're a " .. className .. " .", 0.86, 0.07, 0.23);
	end
end

function CalculatePaladinDamage()

	--Talent information
	_, _, _, _, judgementModifier , _ = GetTalentInfo(3, 3);
	_, _, _, _, sotcRank , _ = GetTalentInfo(3, 4);
	_, _, _, _, wepspecModifier , _ = GetTalentInfo(3, 12);
	_, _, _, _, sanctityModifier , _ = GetTalentInfo(3, 13);
	_, _, _, _, vengeanceModifier , _ = GetTalentInfo(3, 14);
	_, _, _, _, precisionRank , _ = GetTalentInfo(2, 3);
	
	holySpellPower = 140;
	sealOfTheCrusaderAP = 306;
	
	if(judgementModifier == nil) then
		judgementModifier = 0;
	end
	judgementModifier = 10 - judgementModifier;
	if(sotcRank == nil) then
		sotcRank = 0;
	end
	if(wepspecModifier == nil) then
		wepspecModifier = 0;
	end
	wepspecModifier = wepspecModifier * 0.02 + 1;
	if(sanctityModifier == nil) then
		sanctityModifier = 0;
	end
	sanctityModifier = sanctityModifier * 0.1 + 1;
	if(vengeanceModifier == nil) then
		vengeanceModifier = 0;
	end
	vengeanceModifier = vengeanceModifier * 0.03;
	if(precisionRank == nil) then
		precisionRank = 0;
	end
	
	--Increase holy power and attack from seal of the crusader based on items
	libram = GetInventoryItemLink("player", 18);
	gloves = GetInventoryItemLink("player", 10);
	if libram ~= nil and string.find(tostring(libram),  "Fervor") then
		holySpellPower = holySpellPower + 33;
		sealOfTheCrusaderAP =  sealOfTheCrusaderAP + 48;
	end
	if gloves ~= nil and(string.find(tostring(gloves),  "Lamellar Gloves") or string.find(tostring(GetInventoryItemLink("player", 10)),  "Lamellar Gauntlets")) then
		holySpellPower = holySpellPower + 20;
	end
	
	holySpellPower = holySpellPower * (1 + 0.05 * sotcRank);
	sealOfTheCrusaderAP = sealOfTheCrusaderAP * (1 + 0.05 * sotcRank);
	

	--Get necessary character variables
	critChance = GetCritChance() / 100;
	
		mainHandAttackBase, mainHandAttackMod, _, _ = UnitAttackBothHands("player");
	weaponSkill = mainHandAttackBase + mainHandAttackMod;
		minDamage, maxDamage, _, _, _, _, _ = UnitDamage("player");
	weaponDamage = (minDamage + maxDamage) / 2;
	attackSpeed, _ = UnitAttackSpeed("player");
	
	baseAP, posBuffAP, negBuffAP = UnitAttackPower("player");
	attackPower = baseAP + posBuffAP + negBuffAP;
	
	--Calculate hit table values
	hitTable = 1.00;
	hitFromWeaponSkill = 0;
		if(weaponSkill >= 305) then
			hitFromWeaponSkill = hitFromWeaponSkill + 2;
			hitFromWeaponSkill = hitFromWeaponSkill +(weaponSkill - 305) * 0.04;
		else
			hitFromWeaponSkill = hitFromWeaponSkill +(weaponSkill - 300) * 0.04;		
		end
		
	dodgeChance = 0.056;
		if(weaponSkill >= 301) then
			dodgeChance = dodgeChance -(weaponSkill - 300) * 0.0004;		
		end
				
	missChance = 0.08;
	
	hitFromGear = BonusScanner:GetBonus("TOHIT");
	spellPower = BonusScanner:GetBonus("SPELLPOW");
	hitBonus = (hitFromGear + hitFromWeaponSkill + precisionRank) / 100;
	if(hitBonus > 1) then
		hitBonus = 1;
	end
		
	vengeanceUptime = CalcVengeanceUptimeSoC(critChance, attackSpeed);
	hits, crits, miss = CalcAAHitTable(hitBonus, dodgeChance, critChance, missChance);
	aaDmg = Round(CalcRetAutoAttackDamage(weaponDamage, attackSpeed, hits, crits, miss, weaponSkill, vengeanceModifier, vengeanceUptime));
	aaDps = aaDmg / attackSpeed;
	socDmg = CalcSoCDamage(holySpellPower, spellPower, weaponDamage, vengeanceModifier, vengeanceUptime, hits, crits, sanctityModifier, wepspecModifier);
	socDps = socDmg / attackSpeed;
	jocDmg = CalcJoCDamage(holySpellPower, spellPower, vengeanceModifier, vengeanceUptime, hits, crits, sanctityModifier);
	jocDps = jocDmg / judgementModifier;
	totalDps = Round(aaDps + socDps + jocDps);
	
	
	SendMessage("-------------------");
	SendMessage("DPS From SP Consumables");
	SendMessage("Greater Arcane Elixir: ");
	socBonus, jocBonus, consecrationBonus, exorcismBonus, totalBonus = CalcConsumableDamageBonus(35, vengeanceModifier, vengeanceUptime, sanctityModifier, wepspecModifier, hits, crits);
	SendMessage("SoC: +" .. socBonus .. " JoC: +" .. jocBonus .. " Conc: +" .. consecrationBonus .. " !Exorcism: +" .. exorcismBonus);
	SendMessage("Total Bonus: +" .. totalBonus ..  "/s or +" .. Round((totalBonus / totalDps) * 100) .. "% total dps.");
	SendMessage("Arcane Elixir: ");
	socBonus, jocBonus, consecrationBonus, exorcismBonus, totalBonus = CalcConsumableDamageBonus(20, vengeanceModifier, vengeanceUptime, sanctityModifier, wepspecModifier, hits, crits);
	SendMessage("SoC: +" .. socBonus .. " JoC: +" .. jocBonus .. " Conc: +" .. consecrationBonus .. " !Exorcism: +" .. exorcismBonus);
	SendMessage("Total Bonus: +" .. totalBonus ..  "/s or +" .. Round((totalBonus / totalDps) * 100) .. "% total dps.");
	SendMessage("Flask of Supreme Power: ");
	socBonus, jocBonus, consecrationBonus, exorcismBonus, totalBonus = CalcConsumableDamageBonus(150, vengeanceModifier, vengeanceUptime, sanctityModifier, wepspecModifier, hits, crits);
	SendMessage("SoC: +" .. socBonus .. " JoC: +" .. jocBonus .. " Conc: +" .. consecrationBonus .. " !Exorcism: +" .. exorcismBonus);
	SendMessage("Total Bonus: +" .. totalBonus ..  "/s or +" .. Round((totalBonus / totalDps) * 100) .. "% total dps.");
	SendMessage("Total bonus excludes consecration and exorcism.");
	SendMessage("-------------------");
	
	SendMessage("-------------------");
	SendMessage("Vengeance uptime: " .. Round(vengeanceUptime * 100) .. "%");
	SendMessage("AA: " .. Round(aaDmg) .. " or " .. Round(aaDps) .. "/s.");
	SendMessage("SoC: " .. Round(socDmg) .. " or " .. Round(socDps) .. "/s.");
	SendMessage("JoC: " .. Round(jocDmg) .. " or " .. Round(jocDps) .. "/s.");
	SendMessage("Total DPS: " .. totalDps);
	SendMessage("-------------------");
	
	
	hits, crits, miss = CalcAAHitTable(hitBonus + 0.01, dodgeChance, critChance, missChance);
	MaaDmg = Round(CalcRetAutoAttackDamage(weaponDamage, attackSpeed, hits, crits, miss, weaponSkill, vengeanceModifier, vengeanceUptime));
	MsocDmg = CalcSoCDamage(holySpellPower, spellPower, weaponDamage, vengeanceModifier, vengeanceUptime, hits, crits, sanctityModifier, wepspecModifier);
	MsocDps = MsocDmg / attackSpeed;
	MaaDps = MaaDmg / attackSpeed;
	MjocDmg = CalcJoCDamage(holySpellPower, spellPower, vengeanceModifier, vengeanceUptime, hits, crits, sanctityModifier);
	MjocDps = MjocDmg / judgementModifier;
	newDps = Round((MaaDps + MsocDps + MjocDps) - totalDps);
	if(newDps > 0) then
		SendMessage("-------------------");
		SendMessage("Adding 1% Hit results in:");
		SendMessage("AA: +" .. Round(MaaDmg - aaDmg) .. " or +" .. Round(MaaDps - aaDps) .. "/s.");
		SendMessage("SoC: +" .. Round(MsocDmg - socDmg) .. " or +" .. Round(MsocDps - socDps) .. "/s.");
		SendMessage("JoC: +" .. Round(MjocDmg - jocDmg) .. " or +" .. Round(MjocDps - jocDps) .. "/s.");
		SendMessage("Total DPS: +" .. newDps);
		SendMessage("-------------------");
	end
	
	SendMessage("-------------------");
	SendMessage("Adding 1% Crit results in:");
	MvengeanceUptime = CalcVengeanceUptimeSoC(critChance + 0.01, attackSpeed);
	SendMessage("Vengeance uptime: " .. Round((MvengeanceUptime / vengeanceUptime - 1) * 100) .. "% increase.");
	hits, crits, miss = CalcAAHitTable(hitBonus, dodgeChance, critChance + 0.01, missChance);
	MaaDmg = Round(CalcRetAutoAttackDamage(weaponDamage, attackSpeed, hits, crits, miss, weaponSkill, vengeanceModifier, MvengeanceUptime));
	MaaDps = MaaDmg / attackSpeed;
	SendMessage("AA: +" .. Round(MaaDmg - aaDmg) .. " or +" .. Round(MaaDps - aaDps) .. "/s.");
	MsocDmg = CalcSoCDamage(holySpellPower, spellPower, weaponDamage, vengeanceModifier, MvengeanceUptime, hits, crits, sanctityModifier, wepspecModifier);
	MsocDps = MsocDmg / attackSpeed;
	SendMessage("SoC: +" .. Round(MsocDmg - socDmg) .. " or +" .. Round(MsocDps - socDps) .. "/s.");
	MjocDmg = CalcJoCDamage(holySpellPower, spellPower, vengeanceModifier, MvengeanceUptime, hits, crits, sanctityModifier);
	MjocDps = MjocDmg / judgementModifier;
	SendMessage("JoC: +" .. Round(MjocDmg - jocDmg) .. " or +" .. Round(MjocDps - jocDps) .. "/s.");
	SendMessage("Total DPS: +" .. Round((MaaDps + MsocDps + MjocDps) - totalDps));
	SendMessage("-------------------");
	
end

function CalcRetAutoAttackDamage(weaponDamage, attackSpeed, hits, crits, miss, weaponSkill, vengeanceModifier, vengeanceUptime)
	damage = (0.4 * weaponDamage * CalcGlance(weaponSkill) + weaponDamage * hits + (weaponDamage * 2 * crits));
	return (1 + vengeanceModifier * vengeanceUptime) * damage;
end

function CalcSoCDamage(holySpellPower, spellPower, weaponDamage, vengeanceModifier, vengeanceUptime, hits, crits, sanctityModifier, wepspecModifier)
	dmg = (holySpellPower * 0.29 + weaponDamage * 0.7 + spellPower * 0.2) * (1 + vengeanceModifier * vengeanceUptime) * sanctityModifier * wepspecModifier * 1.15;	--1.15 = nightfall
	return hits * dmg + crits * 2 * dmg;
end

function CalcJoCDamage(holySpellPower, spellPower, vengeanceModifier, vengeanceUptime, hits, crits, sanctityModifier)
	dmg = (178 + (holySpellPower + spellPower) * 0.43) * (1 + vengeanceModifier * vengeanceUptime) * sanctityModifier * 1.15;	--1.15 = nightfall
	return hits * dmg + crits * 2 * dmg;
end

function CalcConsumableDamageBonus(bonus, vengeanceModifier, vengeanceUptime, sanctityModifier, wepspecModifier, hits, crits)
	--Soc
	soc = (bonus * 0.2) * (1 + vengeanceModifier * vengeanceUptime) * sanctityModifier * wepspecModifier * 1.15;	--1.15 = nightfall
	soc = hits * soc + crits * 2 * soc;	
	--judgement
	joc = (spellPower * 0.43) * (1 + vengeanceModifier * vengeanceUptime) * sanctityModifier * 1.15;	--1.15 = nightfall
	joc = hits * joc + crits * 2 * joc;
	--consecration
	consecration = (bonus / 24) * (1 + vengeanceModifier * vengeanceUptime) * sanctityModifier;
	--exorcism
	exorcism = ((bonus * 0.43) * (1 + vengeanceModifier * vengeanceUptime) * sanctityModifier * 1.15)/ 15;
	total = Round(soc + joc);
	return Round(soc), Round(joc), Round(consecration), Round(exorcism), total;
end

function CalcAAHitTable(hitBonus, dodgeChance, critChance, missChance)
	miss =  missChance - hitBonus;
	crits = critChance;
	if(miss < 0) then
		miss = 0;
	end
	hits = 0.6 - dodgeChance - miss;			--glances are always 40%;
	if((hits - crits) < 0) then
		crits = hits;
		hits = 0;
	else
		hits = hits - crits;
	end
	return hits, crits, miss;
end

function CalcVengeanceUptimeSoC(critChance, attackSpeed)
	return 1 - math.pow(1-critChance, 1.0 + (7 / 60 * attackSpeed) * (8 / attackSpeed) + (8 / attackSpeed));
end

function CalcGlance(weaponSkill)
	multiplier = 1.25 - 0.04 * (315 - weaponSkill)
	if multiplier > 1 then
		multiplier = 1
	end
	return multiplier;
end

function SendMessage(message)
	DEFAULT_CHAT_FRAME:AddMessage(message)
end

function Round(value)
	return math.floor(value * 100 + 0.5) / 100
end

--From http://wowwiki.wikia.com/wiki/API_GetCritChance?oldid=218798
 function GetCritChance()
   local critNum;
   local id = 1;
   -- This may vary depending on WoW localizations.
   local atkName = "Attack";
   if (GetSpellName(id, BOOKTYPE_SPELL) ~= atkName) then
     name, texture, offset, numSpells = GetSpellTabInfo(1);
     for i=1, numSpells do
       if (GetSpellName(i,BOOKTYPE_SPELL) == atkName) then
         id = i;
       end
     end
   end
   GameTooltip:SetOwner(WorldFrame,"ANCHOR_NONE");
   GameTooltip:SetSpell(id, BOOKTYPE_SPELL);
   local spellName = GameTooltipTextLeft2:GetText();
   GameTooltip:Hide();
   critNum = string.sub(spellName,0,(string.find(spellName, "%s") -2));
   return critNum;
 end