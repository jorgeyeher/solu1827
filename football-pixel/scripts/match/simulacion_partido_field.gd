extends Control

const GRASS_LIGHT := Color("9ed041")
const GRASS_MID := Color("86c53e")
const GRASS_DARK := Color("2b7a3a")
const LINE := Color("f7fff4")
const NET := Color(1, 1, 1, 0.8)
const FRAME_MARGIN := 44.0
const LINE_WIDTH := 7.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	draw_rect(rect, GRASS_MID)
	_draw_stripes(rect)

	var field = Rect2(
		FRAME_MARGIN,
		FRAME_MARGIN,
		rect.size.x - FRAME_MARGIN * 2.0,
		rect.size.y - FRAME_MARGIN * 2.0
	)
	draw_rect(field, LINE, false, LINE_WIDTH)

	var center = field.position + field.size * 0.5
	draw_line(
		Vector2(center.x, field.position.y),
		Vector2(center.x, field.end.y),
		LINE,
		LINE_WIDTH
	)
	draw_arc(center, field.size.y * 0.165, 0.0, TAU, 96, LINE, LINE_WIDTH)
	draw_circle(center, 5.0, LINE)

	_draw_side_geometry(field, center, true)
	_draw_side_geometry(field, center, false)
	_draw_corner_pixels(field)

func _draw_stripes(rect: Rect2) -> void:
	var stripes := 24
	var stripe_width = rect.size.x / float(stripes)
	for i in range(stripes):
		var color = GRASS_LIGHT if i % 2 == 0 else GRASS_DARK
		draw_rect(Rect2(i * stripe_width, 0.0, stripe_width + 1.0, rect.size.y), color)

func _draw_side_geometry(field: Rect2, center: Vector2, left_side: bool) -> void:
	var penalty_height = field.size.y * 0.44
	var penalty_width = field.size.x * 0.165
	var small_height = field.size.y * 0.235
	var small_width = field.size.x * 0.058
	var goal_width = field.size.x * 0.033
	var arc_radius = field.size.y * 0.105

	var penalty_y = center.y - penalty_height * 0.5
	var small_y = center.y - small_height * 0.5

	if left_side:
		var big_box = Rect2(field.position.x, penalty_y, penalty_width, penalty_height)
		var small_box = Rect2(field.position.x, small_y, small_width, small_height)
		var goal = Rect2(field.position.x - goal_width, center.y - small_height * 0.42, goal_width, small_height * 0.84)
		draw_rect(big_box, LINE, false, LINE_WIDTH)
		draw_rect(small_box, LINE, false, LINE_WIDTH)
		_draw_goal_net(goal)
		draw_arc(
			Vector2(big_box.end.x, center.y),
			arc_radius,
			-PI * 0.33,
			PI * 0.33,
			42,
			LINE,
			LINE_WIDTH
		)
	else:
		var big_box = Rect2(field.end.x - penalty_width, penalty_y, penalty_width, penalty_height)
		var small_box = Rect2(field.end.x - small_width, small_y, small_width, small_height)
		var goal = Rect2(field.end.x, center.y - small_height * 0.42, goal_width, small_height * 0.84)
		draw_rect(big_box, LINE, false, LINE_WIDTH)
		draw_rect(small_box, LINE, false, LINE_WIDTH)
		_draw_goal_net(goal)
		draw_arc(
			Vector2(big_box.position.x, center.y),
			arc_radius,
			PI * 0.67,
			PI * 1.33,
			42,
			LINE,
			LINE_WIDTH
		)

func _draw_goal_net(goal_rect: Rect2) -> void:
	draw_rect(goal_rect, LINE, false, 6.0)
	var rows := 7
	var cols := 5
	for row in range(rows):
		var y = goal_rect.position.y + (goal_rect.size.y / float(rows)) * row
		draw_line(Vector2(goal_rect.position.x, y), Vector2(goal_rect.end.x, y), NET, 2.0)
	for col in range(cols):
		var x = goal_rect.position.x + (goal_rect.size.x / float(cols)) * col
		draw_line(Vector2(x, goal_rect.position.y), Vector2(x, goal_rect.end.y), NET, 2.0)

func _draw_corner_pixels(field: Rect2) -> void:
	var corners = [
		{"origin": field.position, "dir": Vector2(1, 1)},
		{"origin": Vector2(field.end.x, field.position.y), "dir": Vector2(-1, 1)},
		{"origin": Vector2(field.position.x, field.end.y), "dir": Vector2(1, -1)},
		{"origin": field.end, "dir": Vector2(-1, -1)}
	]

	for corner in corners:
		_draw_corner_shape(corner.origin, corner.dir)

func _draw_corner_shape(origin: Vector2, direction: Vector2) -> void:
	var steps = [0.0, 16.0, 30.0]
	var lengths = [40.0, 24.0, 12.0]

	for i in range(steps.size()):
		var offset = steps[i]
		var length = lengths[i]
		draw_line(
			origin + Vector2(offset * direction.x, 0.0),
			origin + Vector2((offset + length) * direction.x, 0.0),
			LINE,
			LINE_WIDTH
		)
		draw_line(
			origin + Vector2(0.0, offset * direction.y),
			origin + Vector2(0.0, (offset + length) * direction.y),
			LINE,
			LINE_WIDTH
		)
