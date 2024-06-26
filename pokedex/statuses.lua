local M = {}

M.status = {
	BURNING=1,
	FROZEN=2,
	PARALYZED=3,
	POISONED=4,
	ASLEEP=5,
	CONFUSED=6,
}

M.status_names = {
	[M.status.BURNING] = "Burning",
	[M.status.FROZEN] = "Frozen",
	[M.status.PARALYZED] = "Paralyzed",
	[M.status.POISONED] = "Poisoned",
	[M.status.ASLEEP] = "Asleep",
	[M.status.CONFUSED] = "Confused"
}

M.status_images = {
	[M.status.BURNING] = "burn",
	[M.status.FROZEN] = "frozen",
	[M.status.PARALYZED] = "paralyze",
	[M.status.POISONED] = "poisoned",
	[M.status.ASLEEP] = "sleep",
	[M.status.CONFUSED] = "confuse"
}

M.string_to_state = {
	Burning = M.status.BURNING,
	Frozen = M.status.FROZEN,
	Paralyzed = M.status.PARALYZED,
	Poisoned = M.status.POISONED,
	Asleep = M.status.ASLEEP,
	Confused = M.status.CONFUSED
}

M.status_colors = {
	[M.status.BURNING] = vmath.vector4(0.96, 0.50, 0.19, 1),
	[M.status.FROZEN] = vmath.vector4(0.6, 0.85, 0.85, 1),
	[M.status.PARALYZED] = vmath.vector4(0.97, 0.816, .19, 1),
	[M.status.POISONED] = vmath.vector4(0.63, 0.21, 0.63, 1),
	[M.status.ASLEEP] = vmath.vector4(0.55, 0.53, 0.55, 1),
	[M.status.CONFUSED] = vmath.vector4(0.79, 0.53, 0.40, 1)
}

M.faded_status_colors = {
	[M.status.BURNING] = vmath.vector4(1, 0.871, 0.733, 1),
	[M.status.FROZEN] = vmath.vector4(0.769, 0.902, 0.91, 1),
	[M.status.PARALYZED] = vmath.vector4(0.973, 0.929, .514, 1),
	[M.status.POISONED] = vmath.vector4(0.89, 0.769, 0.922, 1),
	[M.status.ASLEEP] = vmath.vector4(0.824, 0.824, 0.824, 1),
	[M.status.CONFUSED] = vmath.vector4(0.882, 0.816, 0.784, 1)
}

return M