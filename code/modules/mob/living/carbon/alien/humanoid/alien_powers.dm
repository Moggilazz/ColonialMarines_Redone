/*NOTES:
These are general powers. Specific powers are stored under the appropriate alien creature type.
*/

/*Alien spit now works like a taser shot. It won't home in on the target but will act the same once it does hit.
Doesn't work on other aliens/AI.*/

/datum/action/spell_action/alien

/datum/action/spell_action/alien/UpdateName()
	var/obj/effect/proc_holder/alien/ab = target
	return ab.name

/datum/action/spell_action/alien/IsAvailable()
	if(!target)
		return 0
	var/obj/effect/proc_holder/alien/ab = target

	if(usr)
		return ab.cost_check(ab.check_turf,usr,1)
	else
		if(owner)
			return ab.cost_check(ab.check_turf,owner,1)
	return 1

/datum/action/spell_action/alien/CheckRemoval()
	if(!iscarbon(owner))
		return 1

	var/mob/living/carbon/C = owner
	if(target.loc && !(target.loc in C.internal_organs))
		return 1

	return 0


/obj/effect/proc_holder/alien
	name = "Alien Power"
	panel = "Alien"
	var/plasma_cost = 0
	var/check_turf = 0

	var/has_action = 1
	var/datum/action/spell_action/alien/action = null
	var/action_icon = 'icons/mob/actions.dmi'
	var/action_icon_state = "spell_default"
	var/action_background_icon_state = "bg_alien"

/obj/effect/proc_holder/alien/Click()
	if(!istype(usr,/mob/living/carbon))
		return 1
	var/mob/living/carbon/user = usr
	if(cost_check(check_turf,user))
		if(fire(user) && user) // Second check to prevent runtimes when evolving
			user.adjustPlasma(-plasma_cost)
	return 1

/obj/effect/proc_holder/alien/proc/on_gain(mob/living/carbon/user)
	return

/obj/effect/proc_holder/alien/proc/on_lose(mob/living/carbon/user)
	return

/obj/effect/proc_holder/alien/proc/fire(mob/living/carbon/user)
	return 1

/obj/effect/proc_holder/alien/proc/cost_check(check_turf=0,mob/living/carbon/user,silent = 0)
	if(user.stat)
		if(!silent)
			user << "<span class='noticealien'>You must be conscious to do this.</span>"
		return 0
	if(user.getPlasma() < plasma_cost)
		if(!silent)
			user << "<span class='noticealien'>Not enough plasma stored.</span>"
		return 0
	if(check_turf && (!isturf(user.loc) || istype(user.loc, /turf/space)))
		if(!silent)
			user << "<span class='noticealien'>Bad place for a garden!</span>"
		return 0
	return 1

/obj/effect/proc_holder/alien/proc/build_lay_fail(mob/living/carbon/user)
	if((locate(/obj/structure/alien/egg) in get_turf(user)) || (locate(/obj/royaljelly) in get_turf(user)) || (locate(/obj/structure/mineral_door/resin) in get_turf(user)) || (locate(/obj/structure/alien/resin/wall) in get_turf(user)) || (locate(/obj/structure/alien/resin/membrane) in get_turf(user)) || (locate(/obj/structure/stool/bed/nest) in get_turf(user)))
		user << "<span class='danger'>There is already a resin structure there.</span>"
		return 1
	else
		return 0

/obj/effect/proc_holder/alien/plant
	name = "Plant Weeds"
	desc = "Plants some alien weeds"
	plasma_cost = 50
	check_turf = 1
	action_icon_state = "alien_plant"

/obj/effect/proc_holder/alien/plant/fire(mob/living/carbon/user)
	if(locate(/obj/structure/alien/weeds/node) in get_turf(user))
		src << "There's already a weed node here."
		return 0
	for(var/mob/O in viewers(user, null))
		O.show_message(text("<span class='alertalien'>[user] has planted some alien weeds!</span>"), 1)
	new/obj/structure/alien/weeds/node(user.loc)
	return 1

/obj/effect/proc_holder/alien/whisper
	name = "Whisper"
	desc = "Whisper to someone"
	plasma_cost = 10
	action_icon_state = "alien_whisper"

/obj/effect/proc_holder/alien/whisper/fire(mob/living/carbon/user)
	var/mob/living/M = input("Select who to whisper to:","Whisper to?",null) as mob in oview(user)
	if(!M)
		return 0
	var/msg = sanitize(input("Message:", "Alien Whisper") as text|null)
	if(msg)
		log_say("AlienWhisper: [key_name(user)]->[M.key] : [msg]")
		M << "<span class='noticealien'>You hear a strange, alien voice in your head...</span>[msg]"
		user << {"<span class='noticealien'>You said: "[msg]" to [M]</span>"}
	else
		return 0
	return 1

/obj/effect/proc_holder/alien/transfer
	name = "Transfer Plasma"
	desc = "Transfer Plasma to another alien"
	plasma_cost = 0
	action_icon_state = "alien_transfer"

/obj/effect/proc_holder/alien/transfer/fire(mob/living/carbon/user)
	var/list/mob/living/carbon/aliens_around = list()
	for(var/mob/living/carbon/A  in oview(user))
		if(A.getorgan(/obj/item/organ/internal/alien/plasmavessel))
			aliens_around.Add(A)
	var/mob/living/carbon/M = input("Select who to transfer to:","Transfer plasma to?",null) as mob in aliens_around
	if(!M)
		return 0
	var/amount = input("Amount:", "Transfer Plasma to [M]") as num
	if (amount)
		amount = min(abs(round(amount)), user.getPlasma())
		if (get_dist(user,M) <= 1)
			M.adjustPlasma(amount)
			user.adjustPlasma(-amount)
			M << "<span class='noticealien'>[user] has transfered [amount] plasma to you.</span>"
			user << {"<span class='noticealien'>You trasfer [amount] plasma to [M]</span>"}
		else
			user << "<span class='noticealien'>You need to be closer!</span>"
	return

/obj/effect/proc_holder/alien/acid
	name = "Corrossive Acid"
	desc = "Drench an object in acid, destroying it over time."
	plasma_cost = 200
	action_icon_state = "alien_acid"

/obj/effect/proc_holder/alien/acid/on_gain(mob/living/carbon/user)
	user.verbs.Add(/mob/living/carbon/proc/corrosive_acid)

/obj/effect/proc_holder/alien/acid/on_lose(mob/living/carbon/user)
	user.verbs.Remove(/mob/living/carbon/proc/corrosive_acid)

/obj/effect/proc_holder/alien/acid/proc/corrode(target,mob/living/carbon/user = usr)
	if(target in oview(1,user))
		// OBJ CHECK
		if(isobj(target))
			var/obj/I = target
			if(I.unacidable)	//So the aliens don't destroy energy fields/singularies/other aliens/etc with their acid.
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
		// TURF CHECK
		else if(istype(target, /turf/simulated))
			var/turf/T = target
			// R WALL
			if(istype(T, /turf/simulated/wall/r_wall))
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
			// R FLOOR
			if(istype(T, /turf/simulated/floor/engine))
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
		else// Not a type we can acid.
			return 0
		new /obj/effect/acid(get_turf(target), target)
		user.visible_message("<span class='alertalien'>[user] vomits globs of vile stuff all over [target]. It begins to sizzle and melt under the bubbling mess of acid!</span>")
		return 1
	else
		src << "<span class='noticealien'>Target is too far away.</span>"
		return 0


/obj/effect/proc_holder/alien/acid/fire(mob/living/carbon/alien/user)
	var/O = input("Select what to dissolve:","Dissolve",null) as obj|turf in oview(1,user)
	if(!O) return 0
	return corrode(O,user)

/mob/living/carbon/proc/corrosive_acid(O as obj|turf in oview(1)) // right click menu verb ugh
	set name = "Corrossive Acid"

	if(!iscarbon(usr))
		return
	var/mob/living/carbon/user = usr
	var/obj/effect/proc_holder/alien/acid/A = locate() in user.abilities
	if(!A) return
	if(user.getPlasma() > A.plasma_cost && A.corrode(O))
		user.adjustPlasma(-A.plasma_cost)

/obj/effect/proc_holder/alien/acid_strong
	name = "Strong Corrossive Acid"
	desc = "Drench an object in acid, destroying it over time."
	plasma_cost = 300
	action_icon_state = "alien_acid"

/obj/effect/proc_holder/alien/acid_strong/on_gain(mob/living/carbon/user)
	user.verbs.Add(/mob/living/carbon/proc/corrosive_acid_strong)

/obj/effect/proc_holder/alien/acid_strong/on_lose(mob/living/carbon/user)
	user.verbs.Remove(/mob/living/carbon/proc/corrosive_acid_strong)

/obj/effect/proc_holder/alien/acid_strong/proc/corrode(target,mob/living/carbon/user = usr)
	if(target in oview(1,user))
		// OBJ CHECK
		if(isobj(target))
			var/obj/I = target
			if(I.unacidable)	//So the aliens don't destroy energy fields/singularies/other aliens/etc with their acid.
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
		// TURF CHECK
		else if(istype(target, /turf/simulated))
			var/turf/T = target
			// R WALL
			if(istype(T, /turf/simulated/wall/r_wall))
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
			// R FLOOR
			if(istype(T, /turf/simulated/floor/engine))
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
		else// Not a type we can acid.
			return 0
		new /obj/effect/acid/strong(get_turf(target), target)
		user.visible_message("<span class='alertalien'>[user] vomits globs of vile stuff all over [target]. It begins to sizzle and melt under the bubbling mess of acid!</span>")
		return 1
	else
		src << "<span class='noticealien'>Target is too far away.</span>"
		return 0

/obj/effect/proc_holder/alien/acid_strong/fire(mob/living/carbon/alien/user)
	var/O = input("Select what to dissolve:","Dissolve",null) as obj|turf in oview(1,user)
	if(!O) return 0
	return corrode(O,user)

/mob/living/carbon/proc/corrosive_acid_strong(O as obj|turf in oview(1)) // right click menu verb ugh
	set name = "Strong Corrossive Acid"

	if(!iscarbon(usr))
		return
	var/mob/living/carbon/user = usr
	var/obj/effect/proc_holder/alien/acid_strong/A = locate() in user.abilities
	if(!A) return
	if(user.getPlasma() > A.plasma_cost && A.corrode(O))
		user.adjustPlasma(-A.plasma_cost)

/obj/effect/proc_holder/alien/acid_weak
	name = "Weak Corrossive Acid"
	desc = "Drench an object in acid, destroying it over time."
	plasma_cost = 100
	action_icon_state = "alien_acid"

/obj/effect/proc_holder/alien/acid_weak/on_gain(mob/living/carbon/user)
	user.verbs.Add(/mob/living/carbon/proc/corrosive_acid_weak)

/obj/effect/proc_holder/alien/acid_weak/on_lose(mob/living/carbon/user)
	user.verbs.Remove(/mob/living/carbon/proc/corrosive_acid_weak)

/obj/effect/proc_holder/alien/acid_weak/proc/corrode(target,mob/living/carbon/user = usr)
	if(target in oview(1,user))
		// OBJ CHECK
		if(isobj(target))
			var/obj/I = target
			if(I.unacidable)	//So the aliens don't destroy energy fields/singularies/other aliens/etc with their acid.
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
		// TURF CHECK
		else if(istype(target, /turf/simulated))
			var/turf/T = target
			// R WALL
			if(istype(T, /turf/simulated/wall/r_wall))
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
			// R FLOOR
			if(istype(T, /turf/simulated/floor/engine))
				user << "<span class='noticealien'>You cannot dissolve this object.</span>"
				return 0
		else// Not a type we can acid.
			return 0
		new /obj/effect/acid/weak(get_turf(target), target)
		user.visible_message("<span class='alertalien'>[user] vomits globs of vile stuff all over [target]. It begins to sizzle and melt under the bubbling mess of acid!</span>")
		return 1
	else
		src << "<span class='noticealien'>Target is too far away.</span>"
		return 0

/obj/effect/proc_holder/alien/acid_weak/fire(mob/living/carbon/alien/user)
	var/O = input("Select what to dissolve:","Dissolve",null) as obj|turf in oview(1,user)
	if(!O) return 0
	return corrode(O,user)

/mob/living/carbon/proc/corrosive_acid_weak(O as obj|turf in oview(1)) // right click menu verb ugh
	set name = "Weak Corrossive Acid"

	if(!iscarbon(usr))
		return
	var/mob/living/carbon/user = usr
	var/obj/effect/proc_holder/alien/acid_weak/A = locate() in user.abilities
	if(!A) return
	if(user.getPlasma() > A.plasma_cost && A.corrode(O))
		user.adjustPlasma(-A.plasma_cost)

/obj/effect/proc_holder/alien/neurotoxin
	name = "Neurotoxin"
	desc = "Use shift + LMB"
	plasma_cost = 75
	action_icon_state = "alien_neurotoxin"

/obj/effect/proc_holder/alien/neurotoxin/fire(mob/living/carbon/alien/user)
	return 0
/*	user.visible_message("<span class='danger'>[user] spits neurotoxin!", "<span class='alertalien'>You spit neurotoxin.</span>")

	var/turf/T = user.loc
	var/turf/U = get_step(user, user.dir) // Get the tile infront of the move, based on their direction
	if(!isturf(U) || !isturf(T))
		return 0

	var/obj/item/projectile/bullet/neurotoxin/A = new /obj/item/projectile/bullet/neurotoxin(user.loc)
	A.original = U
	A.current = U
	A.starting = T
	A.yo = U.y - T.y
	A.xo = U.x - T.x
	A.fire()

	return 1*/

/obj/effect/proc_holder/alien/neurotoxin_weak
	name = "Weak Neurotoxin"
	desc = "Use shift + LMB"
	plasma_cost = 75
	action_icon_state = "alien_neurotoxin"

/obj/effect/proc_holder/alien/neurotoxin_weak/fire(mob/living/carbon/alien/user)
	return 0
/*	user.visible_message("<span class='danger'>[user] spits neurotoxin!", "<span class='alertalien'>You spit neurotoxin.</span>")

	var/turf/T = user.loc
	var/turf/U = get_step(user, user.dir) // Get the tile infront of the move, based on their direction
	if(!isturf(U) || !isturf(T))
		return 0

	var/obj/item/projectile/bullet/neurotoxin_weak/A = new /obj/item/projectile/bullet/neurotoxin_weak(user.loc)
	A.original = U
	A.current = U
	A.starting = T
	A.yo = U.y - T.y
	A.xo = U.x - T.x
	A.fire()

	return 1*/

/obj/effect/proc_holder/alien/acid_launcher
	name = "Acid Launcher"
	desc = "Use shift + LMB"
	plasma_cost = 75
	action_icon_state = "alien_neurotoxin"

/obj/effect/proc_holder/alien/acid_launcher/fire(mob/living/carbon/alien/user)
	return 0

/obj/effect/proc_holder/alien/resin
	name = "Secrete Resin"
	desc = "Secrete tough malleable resin."
	plasma_cost = 55
	check_turf = 1
	var/list/structures = list(
		"resin door" = /obj/structure/mineral_door/resin,
		"resin wall" = /obj/structure/alien/resin/wall,
		"resin membrane" = /obj/structure/alien/resin/membrane,
		"resin nest" = /obj/structure/stool/bed/nest)

	action_icon_state = "alien_resin"

/obj/effect/proc_holder/alien/resin/fire(mob/living/carbon/user)
	if(build_lay_fail(user))
		return 0
	var/choice = input("Choose what you wish to shape.","Resin building") as null|anything in structures
	if(!choice) return 0

	user << "<span class='notice'>You shape a [choice].</span>"
	user.visible_message("<span class='notice'>[user] vomits up a thick purple substance and begins to shape it.</span>")

	choice = structures[choice]
	new choice(user.loc)
	return 1

/obj/effect/proc_holder/alien/regurgitate
	name = "Regurgitate"
	desc = "Empties the contents of your stomach"
	plasma_cost = 0
	action_icon_state = "alien_barf"

/obj/effect/proc_holder/alien/regurgitate/fire(mob/living/carbon/user)
	if(user.stomach_contents.len)
		for(var/atom/movable/A in user.stomach_contents)
			user.stomach_contents.Remove(A)
			A.loc = user.loc
			A.update_pipe_vision()
		user.visible_message("<span class='alertealien'>[user] hurls out the contents of their stomach!</span>")
	return

/obj/effect/proc_holder/alien/screech
	name = "Screech"
	desc = "Emit a screech that stuns prey."
	plasma_cost = 250
	action_icon_state = "transmit"
	var/usedscreech = 0

/obj/effect/proc_holder/alien/screech/fire(mob/living/carbon/user)
	if(usedscreech)
		user << "\red Our screech is not ready.."
		return 0
	usedscreech = 1
	for(var/mob/O in view())
		playsound(user.loc, 'sound/effects/screech2.ogg', 25, 1, -1)
		O << "\red [user] emits a paralyzing screech!"

	for (var/mob/living/carbon/human/M in oview())
		if(istype(M.ears, /obj/item/clothing/ears/earmuffs))
			continue
		if (get_dist(user.loc, M.loc) <= 4)
			M.stunned += 3
			M.drop_l_hand()
			M.drop_r_hand()
		else if(get_dist(user.loc, M.loc) >= 5)
			M.stunned += 2

	spawn(300)
		usedscreech = 0
	return 1

/obj/effect/proc_holder/alien/nightvisiontoggle
	name = "Toggle Night Vision"
	desc = "Toggles Night Vision"
	plasma_cost = 0
	has_action = 0 // Has dedicated GUI button already

/obj/effect/proc_holder/alien/nightvisiontoggle/fire(mob/living/carbon/alien/user)
	if(!user.nightvision)
		user.see_in_dark = 8
		user.see_invisible = SEE_INVISIBLE_MINIMUM
		user.nightvision = 1
		user.hud_used.nightvisionicon.icon_state = "nightvision1"
	else if(user.nightvision == 1)
		user.see_in_dark = 4
		user.see_invisible = 45
		user.nightvision = 0
		user.hud_used.nightvisionicon.icon_state = "nightvision0"

	return 1



/mob/living/carbon/proc/getPlasma()
	var/obj/item/organ/internal/alien/plasmavessel/vessel = getorgan(/obj/item/organ/internal/alien/plasmavessel)
	if(!vessel) return 0
	return vessel.storedPlasma


/mob/living/carbon/proc/adjustPlasma(amount)
	var/obj/item/organ/internal/alien/plasmavessel/vessel = getorgan(/obj/item/organ/internal/alien/plasmavessel)
	if(!vessel) return 0
	vessel.storedPlasma = max(vessel.storedPlasma + amount,0)
	vessel.storedPlasma = min(vessel.storedPlasma, vessel.max_plasma) //upper limit of max_plasma, lower limit of 0
	return 1

/mob/living/carbon/alien/adjustPlasma(amount)
	. = ..()
	updatePlasmaDisplay()

/mob/living/carbon/proc/usePlasma(amount)
	if(getPlasma() >= amount)
		adjustPlasma(-amount)
		return 1

	return 0


/proc/cmp_abilities_cost(obj/effect/proc_holder/alien/a, obj/effect/proc_holder/alien/b)
	return b.plasma_cost - a.plasma_cost

/mob/living/carbon/alien/verb/hive_status()
	set name = "Hive Status"
	set desc = "Check the status of your current hive."
	set category = "Alien"

	var/dat = "<html><head><title>Hive Status</title></head><body><h1><B>Hive Status</B></h1>"
	
	if(ticker.mode.aliens.len > 0)
		dat += "<table cellspacing=5><tr><td><b>Name</b></td><td><b>Location</b></td></tr>"
		for(var/mob/living/L in mob_list)
			var/turf/pos = get_turf(L)
			if(L.mind && L.mind.assigned_role)
				if(L.mind.assigned_role == "Alien")
					var/mob/M = L.mind.current
					var/area/player_area = get_area(L)
					if((M) && (pos) && (pos.z == 1 || pos.z == 6))
						dat += "<tr><td>[M.real_name][M.client ? "" : " <i>(mindless)</i>"][M.stat == 2 ? " <b><font color=red>(DEAD)</font></b>" : ""]</td>"
						dat += "<td>[player_area.name] ([pos.x], [pos.y])</td></tr>"
		dat += "</table>"
	dat += "</body></html>"
	usr << browse(dat, "window=roundstatus;size=600x400")
	return
