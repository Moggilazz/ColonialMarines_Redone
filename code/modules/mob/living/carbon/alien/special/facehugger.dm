//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

//TODO: Make these simple_animals

var/const/MIN_IMPREGNATION_TIME = 150 //time it takes to impregnate someone
var/const/MAX_IMPREGNATION_TIME = 200

var/const/MIN_ACTIVE_TIME = 100 //time between being dropped and going idle
var/const/MAX_ACTIVE_TIME = 200

/obj/item/clothing/mask/facehugger
	name = "alien"
	desc = "It has some sort of a tube at the end of its tail."
	icon = 'icons/mob/alien.dmi'
	icon_state = "facehugger"
	item_state = "facehugger"
	density = 1
	layer = 3.3
	w_class = 1 //note: can be picked up by aliens unlike most other items of w_class below 4
	flags = MASKINTERNALS
	throw_range = 1
	tint = 3
	flags_cover = MASKCOVERSEYES | MASKCOVERSMOUTH

	var/stat = CONSCIOUS //UNCONSCIOUS is the idle state in this case
	var/sterile = 0
	var/real = 1 //0 for the toy, 1 for real. Sure I could istype, but fuck that.
	var/strength = 5

	var/attached = 0

	var/mob/living/carbon/target = null
	var/chase_time = 0

/obj/item/clothing/mask/facehugger/New()
	..()
	SSobj.processing += src

/obj/item/clothing/mask/facehugger/Destroy()
	SSobj.processing.Remove(src)
	..()

/obj/item/clothing/mask/facehugger/CanPass(atom/movable/mover, turf/target, height=0)
	if(ismob(mover))
		return 1
	if(stat == DEAD)
		return 1
	else
		return 0

/obj/item/clothing/mask/facehugger/process()
	if(facehugger_ai)
		if(!stat)
			//With moving FHs i think we don't need this.
			/*if(!ismob(loc))
				var/turf/T = get_turf(src)
				for(var/obj/O in T.contents)
					if(istype(O, /obj/structure/alien/resin/membrane))
						Die()
					else if(istype(O, /obj/structure/alien/resin/wall))
						Die()
					else if(istype(O, /obj/machinery/door))
						var/obj/machinery/door/D = O
						if(D.density)
							Die()
					else if(istype(O, /obj/structure/mineral_door))
						var/obj/structure/mineral_door/MD = O
						if(MD.density)
							Die()*/
			spawn()
				if(isturf(loc))
					if(!target)
						for(var/mob/living/carbon/C in range(7, src))
							var/obj/effect/vision/V = new /obj/effect/vision(get_turf(src))
							V.target = C
							if(V.check())
								qdel(V)
								if(CanHug(C,0))
									chase_time = 28
									target = C
									chase()
									break
								else
									continue
							else
								qdel(V)
								continue
						if(!target && prob(65))
							step(src, pick(cardinal))

/obj/item/clothing/mask/facehugger/proc/chase()
	while(target)
		if(!isturf(loc))
			target = null
			return
		else if(stat)
			target = null
			return

		for(var/mob/living/carbon/C in range(4, src))
			if(C != target)
				if(CanHug(C,0))
					if(get_dist(src,C) < get_dist(src,target))
						target = C
						break
					else
						continue
				else
					continue

		if(!CanHug(target,0))
			target = null
			return
		else if(get_dist(src,target) < 2)
			Attach(target)
			target = null
			return
		else if(target in view(7,src))
			step_to(src,target)
		else if(chase_time > 0)
			chase_time--
			step_towards(src,target)
		else
			target = null
			return
		sleep(5)

/obj/effect/vision
	invisibility = 101
	var/target = null

/obj/effect/vision/proc/check()
	for(var/i = 1, i < 9, i++)
		if(!src || !target)
			return 0
		step_to(src,target)
		if(get_dist(src,target) == 0)
			return 1
	return 0

/obj/item/clothing/mask/facehugger/attack_alien(mob/user) //can be picked up by aliens
	attack_hand(user)
	return

/obj/item/clothing/mask/facehugger/attack_hand(mob/user)
	if((stat == CONSCIOUS && !sterile) && !isalien(user))
		if(Attach(user))
			return
	else
		if(stat == DEAD && isalien(user))
			if(do_after(user, 20, target = src))
				user << "You ate a facehugger."
				qdel(src)
			return

		var/mob/living/carbon/alien/humanoid/carrier/carr = user

		if(carr && istype(carr, /mob/living/carbon/alien/humanoid/carrier))
			if(carr.facehuggers >= x_stats.d_carrier_limit)
				carr << "You can't hold anymore facehuggers. You pick it up"
				..()
				return
			if(stat != DEAD)
				carr << "You pick up a facehugger"
				carr.facehuggers += 1
				qdel(src)

			else
				user << "This facehugger is dead."
				..()
		else
			..()
		return

/obj/item/clothing/mask/facehugger/attack(mob/living/M, mob/user)
	..()
	user.unEquip(src)
	Attach(M)

/obj/item/clothing/mask/facehugger/examine(mob/user)
	..()
	if(!real)//So that giant red text about probisci doesn't show up.
		return
	switch(stat)
		if(DEAD,UNCONSCIOUS)
			user << "<span class='boldannounce'>[src] is not moving.</span>"
		if(CONSCIOUS)
			user << "<span class='boldannounce'>[src] seems to be active!</span>"
	if (sterile)
		user << "<span class='boldannounce'>It looks like the proboscis has been removed.</span>"

/obj/item/clothing/mask/facehugger/attackby(obj/item/O,mob/m, params)
	if(O.force)
		Die()
	return

/obj/item/clothing/mask/facehugger/bullet_act(obj/item/projectile/P)
	if(P.damage)
		Die()
	return

/obj/item/clothing/mask/facehugger/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300)
		Die()
	return

/obj/item/clothing/mask/facehugger/equipped(mob/M)
	Attach(M)

/obj/item/clothing/mask/facehugger/Crossed(atom/target)
	HasProximity(target)
	return

/obj/item/clothing/mask/facehugger/on_found(mob/finder)
	if(stat == CONSCIOUS)
		return HasProximity(finder)
	return 0

/obj/item/clothing/mask/facehugger/HasProximity(atom/movable/AM as mob|obj)
	if(CanHug(AM))
		return Attach(AM)
	return 0

/obj/item/clothing/mask/facehugger/throw_at(atom/target, range, speed, mob/thrower, spin)
	if(!..())
		return
	if(stat == CONSCIOUS)
		icon_state = "[initial(icon_state)]_thrown"
		spawn(15)
			if(icon_state == "[initial(icon_state)]_thrown")
				icon_state = "[initial(icon_state)]"

/obj/item/clothing/mask/facehugger/throw_impact(atom/hit_atom)
	..()
	if(stat == CONSCIOUS)
		icon_state = "[initial(icon_state)]"
		Attach(hit_atom)

/obj/item/clothing/mask/facehugger/proc/Attach(mob/living/M)
	if(!isliving(M)) return 0

	if((!iscorgi(M) && !iscarbon(M)) || isalien(M))
		return 0
	if(attached)
		return 0
	else
		attached++
		spawn(MAX_IMPREGNATION_TIME)
			attached = 0

	if(M.getorgan(/obj/item/organ/internal/alien/hivenode)) return 0
	if(M.getorgan(/obj/item/organ/internal/body_egg/alien_embryo)) return 0

	if(loc == M) return 0
	if(stat != CONSCIOUS)	return 0
	if(!sterile) M.take_organ_damage(strength,0) //done here so that even borgs and humans in helmets take damage

	M.visible_message("<span class='danger'>[src] leaps at [M]'s face!</span>", \
						"<span class='userdanger'>[src] leaps at [M]'s face!</span>")

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/clothing/head/head = H.head
		if(H.is_mouth_covered(head_only = 1))
			head.take_damage(rand(1,3))
			if(head.health <= 2)
				H.visible_message("<span class='danger'>[src] smashes against [H]'s [head], and rips it off in the process!</span>", \
									"<span class='userdanger'>[src] smashes against [H]'s [head], and rips it off in the process!</span>")
				H.unEquip(head)
			else
				H.visible_message("<span class='danger'>[src] smashes against [H]'s [head], and fails to rip it off!</span>", \
								"<span class='userdanger'>[src] smashes against [H]'s [head], and fails to rip it off!</span>")
			if(prob(75))
				Die()
			else
				H.visible_message("<span class='danger'>[src] bounces off of the [head]!</span>", \
								"<span class='userdanger'>[src] bounces off of the [head]!</span>")
				GoIdle()

			return 0

	if(iscarbon(M))
		var/mob/living/carbon/target = M
		if(target.wear_mask)
			if(prob(20))	return 0
			var/obj/item/clothing/W = target.wear_mask
			if(W.flags & NODROP)	return 0
			target.unEquip(W)

			target.visible_message("<span class='danger'>[src] tears [W] off of [target]'s face!</span>", \
									"<span class='userdanger'>[src] tears [W] off of [target]'s face!</span>")

		src.loc = target
		target.equip_to_slot(src, slot_wear_mask,,0)

		if(!sterile) M.Paralyse(MAX_IMPREGNATION_TIME/8) //something like 25 ticks = 20 seconds with the default settings
	else if (iscorgi(M))
		var/mob/living/simple_animal/pet/dog/corgi/C = M
		loc = C
		C.facehugger = src
		C.regenerate_icons()

	GoIdle() //so it doesn't jump the people that tear it off
	//if(!sterile)
	//	src.flags |= NODROP
	spawn(rand(MIN_IMPREGNATION_TIME-x_stats.h_facehugger,MAX_IMPREGNATION_TIME-x_stats.h_facehugger))
		Impregnate(M)

	return 1

/obj/item/clothing/mask/facehugger/proc/Impregnate(mob/living/target)
	if(!target || target.stat == DEAD) //was taken off or something
		return

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(C.wear_mask != src)
			return

	if(!sterile)
		//target.contract_disease(new /datum/disease/alien_embryo(0)) //so infection chance is same as virus infection chance
		target.visible_message("<span class='danger'>[src] falls limp after violating [target]'s face!</span>", \
								"<span class='userdanger'>[src] falls limp after violating [target]'s face!</span>")
		//src.flags &= ~NODROP
		if(iscorgi(target))
			var/mob/living/simple_animal/pet/dog/corgi/C = target
			loc = get_turf(C)
			C.facehugger = null
			C.regenerate_icons()
		else
			target.unEquip(src)
		Die()
		icon_state = "[initial(icon_state)]_impregnated"

		if(!target.getlimb(/obj/item/organ/limb/robot/chest) && !target.getorgan(/obj/item/organ/internal/body_egg/alien_embryo))
			new /obj/item/organ/internal/body_egg/alien_embryo(target)

		if(iscorgi(target))
			var/mob/living/simple_animal/pet/dog/corgi/C = target
			src.loc = get_turf(C)
			C.facehugger = null
	else
		target.visible_message("<span class='danger'>[src] violates [target]'s face!</span>", \
								"<span class='userdanger'>[src] violates [target]'s face!</span>")
	return

/obj/item/clothing/mask/facehugger/proc/GoActive()
	if(stat == DEAD || stat == CONSCIOUS)
		return

	stat = CONSCIOUS
	icon_state = "[initial(icon_state)]"

/*		for(var/mob/living/carbon/alien/alien in world)
		var/image/activeIndicator = image('icons/mob/alien.dmi', loc = src, icon_state = "facehugger_active")
		activeIndicator.override = 1
		if(alien && alien.client)
			alien.client.images += activeIndicator	*/

	return

/obj/item/clothing/mask/facehugger/proc/GoIdle()
	if(stat == DEAD || stat == UNCONSCIOUS)
		return

/*		RemoveActiveIndicators()	*/

	stat = UNCONSCIOUS
	icon_state = "[initial(icon_state)]_inactive"

	spawn(rand(MIN_ACTIVE_TIME,MAX_ACTIVE_TIME))
		GoActive()
	return

/obj/item/clothing/mask/facehugger/proc/Die()
	if(stat == DEAD)
		return

/*		RemoveActiveIndicators()	*/

	density = 0
	icon_state = "[initial(icon_state)]_dead"
	stat = DEAD

	visible_message("<span class='danger'>[src] curls up into a ball!</span>")

	return

/obj/proc/CanHug(mob/living/M,var/check = 1)
	if(!istype(M))
		return 0

	if(check)
		if(isturf(src.loc))
			if(!(M in view(1,src)))
				return 0

	if(M.stat == DEAD)
		return 0

	if(iscorgi(M) || ismonkey(M))
		return 1

	if(isalien(M))
		return 0

	if(M.getorgan(/obj/item/organ/internal/alien/hivenode))
		return 0

	if(M.getorgan(/obj/item/organ/internal/body_egg/alien_embryo))
		return 0

	var/mob/living/carbon/C = M
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if(istype(H.wear_mask, /obj/item/clothing/mask/facehugger))
			var/obj/item/clothing/mask/facehugger/fh = H.wear_mask
			if(fh.stat != DEAD)
				return 0
	//	return 1
	//return 0

	return 1
