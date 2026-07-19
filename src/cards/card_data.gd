class_name CardData
extends RefCounted
## Static definitions for the five Sound Cards.

enum Card { PITCH, TEMPO, FORTE, CHORD, REST }

const DEFS := {
	Card.PITCH: {
		"name": "PITCH",
		"icon": "res://assets/icons/pitch.svg",
		"glyph": "P",  # ASCII-safe (web fonts lack the fancy glyphs)
		"ammo": 24,
		"fire_desc": "Handgun",
		"discard_desc": "Double Jump",
		"fill": "double_jump",
	},
	Card.TEMPO: {
		"name": "TEMPO",
		"icon": "res://assets/icons/tempo.svg",
		"glyph": "T",  # ASCII-safe
		"ammo": 15,
		"fire_desc": "Burst Rifle",
		"discard_desc": "Sound Bomb",
		"fill": "bass_drop",
	},
	Card.FORTE: {
		"name": "FORTE",
		"icon": "res://assets/icons/forte.svg",
		"glyph": "F",  # ASCII-safe
		"ammo": 8,
		"fire_desc": "Shotgun",
		"discard_desc": "Meteor Launch",
		"fill": "meteor",
	},
	Card.CHORD: {
		"name": "CHORD",
		"icon": "res://assets/icons/chord.svg",
		"glyph": "C",  # ASCII-safe
		"ammo": 4,
		"fire_desc": "Rocket Launcher",
		"discard_desc": "Grapple Hook",
		"fill": "grapple",
	},
	Card.REST: {
		# Not a slot card: REST pickups heal 1 HP instantly on touch
		# (see card_pickup.gd). Kept here for the glyph and drop metadata.
		"name": "REST",
		"icon": "res://assets/icons/rest.svg",
		"glyph": "R",  # ASCII-safe
		"ammo": 0,
		"fire_desc": "—",
		"discard_desc": "Instant Heal",
		"fill": "shield",
	},
}


static func get_def(id: int) -> Dictionary:
	return DEFS[id]
