----------------------------------------------------------------------
-- round rectangle ipelet
----------------------------------------------------------------------

label = "Round Rectangle"

about = [[
Round Rectangle
]]

function collect_vertices(model)
  local page = model:page()
  local primary_selection = page:primarySelection()
  if not primary_selection then
    model.ui:warning("No shape is selected")
    return
  end

  local obj = page[primary_selection]
  if obj:type() ~= "path" then
    model:warning("Primary selection is not path")
    return
  end

  local shape = obj:shape()
  if (#shape ~= 1 or shape[1].type ~= "curve") then
    model:warning("Primary selection is not curve")
    return
  end

  local vs = {}
  local m = obj:matrix()
  local segments = shape[1]
  for i = 1, #segments do
    local segment = segments[i]
    local v = segment[1]
    vs[#vs+1] = m * v
  end
  local last_segment = segments[#segments]
  local last_v = m * last_segment[2]
  vs[#vs+1] = last_v

  return {vs=vs, closed=shape[1].closed}
end


function get_rounded_corner(v1, v2, v3, l)
  u1 = (v1 - v2):normalized()
  u2 = (v3 - v2):normalized()
  u3 = (u1 + u2):normalized()

  local cos_theta = u1.x * u3.x + u1.y * u3.y

  if cos_theta == 0 then return end

  local sin_theta = math.sqrt(1 - cos_theta * cos_theta)
  local tan_theta = sin_theta / cos_theta

  if tan_theta == 0 then return end

  local center = v2 + u3 * (l / cos_theta)
  local w1 = v2 + u1 * l
  local w2 = v2 + u2 * l

  return {center=center, w1=w1, w2=w2, radius=tan_theta*l}
end


function get_arc_segment(w1, w2, center, radius)
  local u1 = w1 - center
  local u2 = w2 - center
  local ccw = u1.x * u2.y > u1.y * u2.x
  local m = ipe.Matrix(
      radius, 0, 0, ccw and radius or -radius, center.x, center.y)
  return {type='arc', arc=ipe.Arc(m), w1, w2}
end


function round_corner(model)
  local collected = collect_vertices(model)
  if not collected then return end

  local page = model:page()

  local vs = collected.vs
  local closed = collected.closed
  if #vs < 3 then
    model:warning("The number of vertices is less than 3")
    return
  end

  local dialog = ipeui.Dialog(
      model.ui.win and model.ui:win() or model.ui, "Input a length.")
  dialog:add("length_label", "label", {label="length (pt)"}, 1, 1)
  dialog:add("length", "input", {}, 1, 2)
  dialog:set("length", "16")
  dialog:add("ok", "button", { label="&Ok", action="accept" }, 2, 2)
  dialog:add("cancel", "button", { label="&Cancel", action="reject" }, 2, 1)

  if not dialog:execute() then return end
  local length = tonumber(dialog:get("length"))

  if not length then
    model:warning("length must be a number")
    return
  end
  if length <= 0 then return end

  local shape = {type = "curve", closed = closed}
  local rounded_corners = {}

  local num_corners = closed and #vs or (#vs - 2)

  for i = 1, num_corners do
    v1 = vs[i]
    v2 = vs[((i+1)-1) % #vs + 1]
    v3 = vs[((i+2)-1) % #vs + 1]
    local rounded_corner = get_rounded_corner(v1, v2, v3, length)
    if not rounded_corner then
      model:warning("There exist corners with degree 0 or 180")
      return
    end
    rounded_corners[#rounded_corners+1] = rounded_corner
  end

  if not closed then
    local first_w1 = rounded_corners[1].w1
    shape[#shape+1] = {type='segment', vs[1], first_w1}
  end

  for i = 1, #rounded_corners do
    local center = rounded_corners[i].center
    local w1 = rounded_corners[i].w1
    local w2 = rounded_corners[i].w2
    local radius = rounded_corners[i].radius

    local arc_segment = get_arc_segment(w1, w2, center, radius)
    shape[#shape+1] = arc_segment

    if i ~= #rounded_corners then
      local next_w1 = rounded_corners[i+1].w1
      shape[#shape+1] = {type='segment', w2, next_w1}
    end
  end

  if not closed then
    local last_w2 = rounded_corners[#rounded_corners].w2
    shape[#shape+1] = {type='segment', last_w2, vs[#vs]}
  end

  obj = ipe.Path(model.attributes, {shape})
  model:creation("Rounded result", obj)
end


function create_rounded_rectangle(model)

  local width = 100
  local height = 100
  local radius = 10

  local vs = {
    ipe.Vector(0, 0),
    ipe.Vector(width, 0),
    ipe.Vector(width, height),
    ipe.Vector(0, height),
  }

  local us = {
    vs[1] + ipe.Vector(radius, 0),
    vs[2] + ipe.Vector(-radius, 0),

    vs[2] + ipe.Vector(0, radius),
    vs[3] + ipe.Vector(0, -radius),

    vs[3] + ipe.Vector(-radius, 0),
    vs[4] + ipe.Vector(radius, 0),

    vs[4] + ipe.Vector(0, -radius),
    vs[1] + ipe.Vector(0, radius),
  }

  local radius = 10
  local ws = {
    vs[1] + ipe.Vector(radius, radius),
    vs[2] + ipe.Vector(-radius, radius),
    vs[3] + ipe.Vector(-radius, -radius),
    vs[4] + ipe.Vector(radius, -radius),
  }
  local ms = {
    ipe.Matrix(radius, 0, 0, radius, ws[1].x, ws[1].y),
    ipe.Matrix(radius, 0, 0, radius, ws[2].x, ws[2].y),
    ipe.Matrix(radius, 0, 0, radius, ws[3].x, ws[3].y),
    ipe.Matrix(radius, 0, 0, radius, ws[4].x, ws[4].y),
  }
  local arc_segments = {
    { type='arc', arc=ipe.Arc(ms[1]), us[8], us[1] },
    { type='arc', arc=ipe.Arc(ms[2]), us[2], us[3] },
    { type='arc', arc=ipe.Arc(ms[3]), us[4], us[5] },
    { type='arc', arc=ipe.Arc(ms[4]), us[6], us[7] }
  }

  local shape = {
    type = "curve",
    closed = true,
    arc_segments[1],
    { type='segment', us[1], us[2] },
    arc_segments[2],
    { type='segment', us[3], us[4] },
    arc_segments[3],
    { type='segment', us[5], us[6] },
    arc_segments[4],
    { type='segment', us[7], us[8] },
  }
  local obj = ipe.Path(model.attributes, { shape })
  model:creation("Create rounded rectangle", obj)
end

methods = {
  { label = "Create round rectangle", run = create_rounded_rectangle },
  { label = "Round corner", run = round_corner},
}

