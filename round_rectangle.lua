----------------------------------------------------------------------
-- round rectangle ipelet
----------------------------------------------------------------------

label = "Round Rectangle"

about = [[
Round Rectangle
]]

methods = {
  { label = "create round rectangle" },
}

function run(model, num)
  local page = model:page()

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
  -- page:append(obj, nil, page:layers()[1])
  model:creation("??", obj)
end
