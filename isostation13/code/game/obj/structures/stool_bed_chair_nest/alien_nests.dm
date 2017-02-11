//Alium nests. Essentially beds with an unbuckle delay that only aliums can buckle mobs to.
#define NEST_RESIST_TIME 1200

#define STAGE_FIRST 1
#define STAGE_CONTRACTION_ONE 1
#define STAGE_CONTRACTION_TWO 2
#define STAGE_ABSORBTION 3
#define STAGE_INCORPORATION 4
#define STAGE_RESIN_OVERLAY_ADDED 5
#define STAGE_CONTRACTION_FAILED 6
#define STAGE_LAST 6

/obj/structure/bed/nest
	name = "alien nest"
	desc = "It's a gruesome pile of thick, sticky resin shaped like a nest."
	icon = 'icons/mob/alien_new.dmi'
	icon_state = "nest"
	var/health = 100
	var/progress = 0
	var/list/stages[STAGE_LAST]

/obj/structure/bed/nest/overlay
	layer = MOB_LAYER + 0.01


/obj/structure/bed/nest/New()
	..()
	progress = 0

	reset_stages()
	if (overlays.len)
		clear_overlays()

	processing_objects += src

/obj/structure/bed/nest/Destroy()
	clear_overlays()
	processing_objects -= src
	..()


/obj/structure/bed/nest/proc/resin_overlay()
	if (!stages[STAGE_RESIN_OVERLAY_ADDED])
		overlays += /obj/structure/bed/nest/overlay
		stages[STAGE_RESIN_OVERLAY_ADDED] = 1

/obj/structure/bed/nest/proc/clear_overlays()
	overlays = list()

/obj/structure/bed/nest/proc/stages_need_reset()
	for (var/v = STAGE_FIRST, v <= STAGE_LAST, v++)
		if (stages[v] != FALSE)
			return TRUE
	return FALSE

/obj/structure/bed/nest/proc/reset_stages()
	if (!stages_need_reset())
		return

	stages[STAGE_CONTRACTION_ONE] = FALSE
	stages[STAGE_CONTRACTION_TWO] = FALSE
	stages[STAGE_ABSORBTION] = FALSE
	stages[STAGE_INCORPORATION] = FALSE
	stages[STAGE_RESIN_OVERLAY_ADDED] = FALSE
	stages[STAGE_CONTRACTION_FAILED] = FALSE

/obj/structure/bed/nest/process()//probably shouldn't use ..()
	if (!buckled_mob)
		progress = 0
		reset_stages()
		if (overlays.len)
			clear_overlays()
	else
		++progress
		if (ishuman(buckled_mob) && buckled_mob:alien_embryo != null)
			if (!stages[STAGE_CONTRACTION_FAILED])
				buckled_mob.visible_message(\
					"<span class='notice'>[src] starts to wrap around [buckled_mob.name]'s body, but suddenly stops.</span>",\
					"<span class='danger'>[src] starts contracting around your body, but suddenly stops.</span>",\
					"<span class='warning'>You hear squelching...</span>")
				stages[STAGE_CONTRACTION_FAILED] = TRUE
			return
		switch (progress)
			if (20 to 30)
				if (!stages[STAGE_CONTRACTION_ONE])
					buckled_mob.visible_message(\
						"<span class='notice'>[src] starts to wrap around [buckled_mob.name]'s body.</span>",\
						"<span class='danger'>[src] contracts around your body.</span>",\
						"<span class='warning'>You hear squelching...</span>")
					stages[STAGE_CONTRACTION_ONE] = TRUE
				else if (prob(30))
					buckled_mob.visible_message(\
						"<span class='notice'>[src] squeezes [buckled_mob.name].</span>",\
						"<span class='danger'>[src] squeezes you a bit.</span>",\
						"<span class='warning'>You hear squelching...</span>")

			if (31 to 50)
				if (!stages[STAGE_CONTRACTION_TWO])
					buckled_mob.visible_message(\
						"<span class='notice'>[src] squishes [buckled_mob.name]'s body, starting to absorb them.</span>",\
						"<span class='danger'>[src] is starting to absorb you. This is really unpleasant.</span>",\
						"<span class='warning'>You hear squelching...</span>")
					stages[STAGE_CONTRACTION_TWO] = TRUE
				if (prob(5))
					buckled_mob.adjustBruteLoss(pick(1,2))
					if (prob(40))
						buckled_mob.emote("scream", forced = TRUE)

			//give them a false sense of security for 10 ticks
			if (60 to 120)
			/*
				if (buckled_mob.stat == 2)//if they're already dead here, doesn't matter in incorporation stage
					buckled_mob.visible_message(\
						"<span class='danger'>[src] releases [buckled_mob.name]!</span>",\
						"<span class='notice'>[src] releases your corpse.</span>",\
						"<span class='notice'>You hear loud squelching...</span>")
					var/mob/m = buckled_mob
					buckled_mob = null
					m.loc = get_turf(src)*/

				if ((prob(3) && !stages[STAGE_ABSORBTION]) || (progress > 110 && !stages[STAGE_ABSORBTION]))//probably once or twice? At least once
					resin_overlay()
					buckled_mob.visible_message(\
						"<span class='notice'>[src] fully absorbs [buckled_mob.name]!</span>",\
						"<span class='danger'>[src] fully contracts around your body! You've been absorbed by the nest!</span>",\
						"<span class='warning'>You hear loud squelching...</span>")
					stages[STAGE_ABSORBTION] = TRUE

			if (150 to INFINITY)
				if (prob(1) || progress >= 500)
					if (!stages[STAGE_INCORPORATION])
						buckled_mob.visible_message(\
							"<span class='notice'>[buckled_mob.name] is totally incorporated into [src], which has become an egg.</span>",\
							"<span class='danger'>[src] has morphed your body into an egg.</span>",\
							"<span class='warning'>You hear loud squelching...</span>")
						buckled_mob.gib()
						buckled_mob = null
						new/obj/structure/alien/egg(get_turf(src))
						qdel(src)
						stages[STAGE_INCORPORATION] = TRUE



/obj/structure/bed/nest/update_icon()
	return

/obj/structure/bed/nest/user_unbuckle_mob(mob/user as mob)
	if (stages[STAGE_ABSORBTION]) return
	if(buckled_mob)
		if(buckled_mob.buckled == src)
			if(buckled_mob != user)
				buckled_mob.visible_message(\
					"<span class='notice'>[user.name] pulls [buckled_mob.name] free from the sticky nest!</span>",\
					"<span class='notice'>[user.name] pulls you free from the gelatinous resin.</span>",\
					"<span class='notice'>You hear squelching...</span>")
				buckled_mob.pixel_y = 0
				buckled_mob.old_y = 0
				unbuckle_mob()
			else
				if(world.time <= buckled_mob.last_special+NEST_RESIST_TIME)
					return
				buckled_mob.last_special = world.time
				buckled_mob.visible_message(\
					"<span class='warning'>[buckled_mob.name] struggles to break free of the gelatinous resin...</span>",\
					"<span class='warning'>You struggle to break free from the gelatinous resin...</span>",\
					"<span class='notice'>You hear squelching...</span>")
				spawn(NEST_RESIST_TIME)
					if(user && buckled_mob && user.buckled == src)
						buckled_mob.last_special = world.time
						buckled_mob.pixel_y = 0
						buckled_mob.old_y = 0
						unbuckle_mob()
			src.add_fingerprint(user)
	return

/obj/structure/bed/nest/user_buckle_mob(mob/M as mob, mob/user as mob)
	if ( !ismob(M) || (get_dist(src, user) > 1) || (M.loc != src.loc) || user.restrained() || usr.stat || M.buckled || istype(user, /mob/living/silicon/pai) )
		return

	if (!M.lying && istype(M, /mob/living/carbon)) return

	unbuckle_mob()

	var/mob/living/carbon/xenos = user
	var/mob/living/carbon/victim = M

	if(istype(victim) && locate(/obj/item/organ/xenos/hivenode) in victim.internal_organs)
		return

	if(istype(xenos) && !(locate(/obj/item/organ/xenos/hivenode) in xenos.internal_organs))
		return

	if(M == usr)
		return
	else
		M.visible_message(\
			"<span class='notice'>[user.name] secretes a thick vile goo, securing [M.name] into [src]!</span>",\
			"<span class='warning'>[user.name] drenches you in a foul-smelling resin, trapping you in the [src]!</span>",\
			"<span class='notice'>You hear squelching...</span>")
	M.buckled = src
	M.loc = src.loc
	M.set_dir(src.dir)
	M.update_canmove()
	M.pixel_y = 6
	M.old_y = 6
	src.buckled_mob = M
	src.add_fingerprint(user)
	return

/obj/structure/bed/nest/attackby(obj/item/weapon/W as obj, mob/user as mob)
	var/aforce = W.force
	health = max(0, health - aforce)
	playsound(loc, 'sound/effects/attackblob.ogg', 100, 1)
	for(var/mob/M in viewers(src, 7))
		M.show_message("<span class='warning'>[user] hits [src] with [W]!</span>", 1)
	healthcheck()

/obj/structure/bed/nest/proc/healthcheck()
	if(health <=0)
		density = 0
		qdel(src)
	return
