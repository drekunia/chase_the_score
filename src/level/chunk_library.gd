class_name ChunkLibrary
extends RefCounted
## Hand-authored level chunks (vertical segments ~1-1.5 screens tall) stacked
## by the generator. 15 columns wide, rows listed TOP first.
##
## Legend:
##   .  empty
##   =  standing platform — thin one-way strip, jump up through it
##   S  standing platform, also part of the chunk's designated SAFE zone
##   #  solid structural block (walls, floors, ceilings) — blocks all sides
##   B  breakable block       H  Hopper
##   G  Glitch Shell          T  Bass Block (place directly UNDER a ledge)
##   W  Hook Weaver           M  Metronome (swinging heal-card carrier)
##   ?  random enemy (Hopper / Glitch / Weaver / Metronome) — varies per run
##   !  look-ahead key spawn — the enemy matching this chunk's REQ tag is
##      hard-coded to spawn here, so the key always precedes the lock.
##
## "req" is -1 (none) or a CardData.Card whose discard ability the chunk's
## intended route needs (REQ: JUMP / BOMB / LAUNCH / GRAPPLE).
##
## Tuning notes (base jump clears ~4 tile-rows of height):
##   - Standing platforms are one-way, so you can always jump up through them
##     — vertical spacing never blocks ascent.
##   - Main routes rise 3 rows per platform; platforms are 3-4 tiles wide.
##   - Keep a platform near the top and in the bottom two rows of every chunk
##     so seams stay climbable.

const NO_REQ := -1

const START := {
	"name": "start",
	"req": NO_REQ,
	"weight": 0,
	"rows": [
		"...............",
		"....===........",
		"...............",
		".........===...",
		"...............",
		"....===........",
		"...............",
		"...............",
		".........===...",
		"...............",
		"...............",
		"###############",
	],
}

const CHUNKS := [
	{
		"name": "zigzag",
		"req": NO_REQ,
		"weight": 3,
		"rows": [
			"...............",
			"....===........",
			"...............",
			"...............",
			"........===....",
			"...?...........",
			"..===..........",
			"...............",
			".....M.........",
			"........===....",
			".............W.",
			"....?..........",
			"...====........",
			"...............",
			"...............",
			".........===...",
			"......G...T....",
			".....===.......",
			"...............",
			"...............",
			".........===...",
			"...H...........",
			"..====.........",
			"...............",
		],
	},
	{
		"name": "spine",
		"req": NO_REQ,
		"weight": 3,
		"rows": [
			"...............",
			".........===...",
			"......M........",
			"...............",
			"....===........",
			"...............",
			"......?........",
			".....====......",
			"...............",
			"...............",
			".........===...",
			"..........T....",
			".....BBB....W..",
			"...............",
			"..===..........",
			"...............",
			"....H..........",
			"...===.........",
			"...............",
			"......===......",
		],
	},
	{
		"name": "scatter",
		"req": NO_REQ,
		"weight": 3,
		"rows": [
			"...............",
			"......===......",
			"...............",
			"...............",
			"..===......?...",
			".........===...",
			"...............",
			"W.........M....",
			"....===........",
			"...............",
			"......G........",
			".......===.....",
			"...............",
			"...............",
			"..........===..",
			"...............",
			"......===......",
			".......T.......",
			"...............",
			"..===..........",
			".........H.....",
			"........===....",
			"...............",
			"....===........",
		],
	},
	{
		"name": "req_jump",  # [REQ: JUMP] — PITCH double jump crosses the void
		"req": CardData.Card.PITCH,
		"weight": 2,
		"rows": [
			"...............",
			"....===........",
			"...............",
			".........===...",
			"...............",
			"......HH.......",
			"...............",
			"...............",
			"...............",
			"...=======.....",
			"...............",
			"...!...........",
			"..SSSSSS.......",
			"...............",
			".........===...",
			"...............",
			"...............",
			".....===.......",
		],
	},
	{
		"name": "req_bomb",  # [REQ: BOMB] — TEMPO sound bomb rockets up the shaft
		"req": CardData.Card.TEMPO,
		"weight": 2,
		"rows": [
			"...............",
			"....===........",
			"...............",
			".....===.......",
			"...##.....##...",
			"...##..H..##...",
			"...##.===.##...",
			"...##.....##...",
			"...##..H..##...",
			"...##.===.##...",
			"...##.....##...",
			"...##.BB..##...",
			"...##.....##...",
			"........!......",
			"...SSSSS.......",
			"...............",
			".........===...",
			"...............",
			"...............",
			".....===.......",
		],
	},
	{
		"name": "req_launch",  # [REQ: LAUNCH] — FORTE meteor blasts through the gap
		"req": CardData.Card.FORTE,
		"weight": 2,
		"rows": [
			"...............",
			".....===.......",
			"...............",
			"...............",
			"..H.......H....",
			"...............",
			"...............",
			"...............",
			"...............",
			"####......#####",
			"....!..........",
			"...............",
			"...H..G..?.....",
			"..SSS....===...",
			"...............",
			"...............",
			".....===.......",
			"...............",
			"...............",
			"......===......",
		],
	},
	{
		"name": "req_grapple",  # [REQ: GRAPPLE] — CHORD tether crosses the chasm
		"req": CardData.Card.CHORD,
		"weight": 2,
		"rows": [
			"...............",
			"....===........",
			"......H........",
			"......==.......",
			"...............",
			"..........W....",
			"...............",
			"....H..........",
			"....==.........",
			"...............",
			"...............",
			"........H......",
			"........==.....",
			"...............",
			"W..............",
			"....H..........",
			"....==.........",
			"...............",
			"....!..........",
			"..SSSSS........",
			"...............",
			".........===...",
			"...............",
			"......===......",
		],
	},
]
