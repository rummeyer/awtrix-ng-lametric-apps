# @name Clock
# @desc The time beside LaMetric's flame with the weekday under it, as LaMetric's Alarm Clock
# @author Oliver Rummeyer
# @version 2.0
# @config showicon bool "Icon" default=true
# @config weekday bool "Weekday" default=true
# @config monday bool "Week starts Monday" default=true group="Weekday"
# @config today color "Today" default=#FFFFFF group="Weekday"
# @config other color "Other days" default=#666666 group="Weekday"
# @config quiet bool "Quiet hours" default=false group="Quiet hours"
# @config qfrom number "From" default=23 min=0 max=23 unit=h group="Quiet hours"
# @config qto number "To" default=8 min=0 max=23 unit=h group="Quiet hours"
# @config qdim slider "Brightness" default=1 min=0 max=100 unit=% group="Quiet hours"
import string
import math
class Clock
var fg, tc, ic, io, tall, pc, hm, cells, cq, qnow, shown, sec, sep, font2, wk, monday, today, other
def init()
self.fg = settings.get("textColor")
if self.fg == nil self.fg = 0xFFFFFF end
self.tc = settings.get("timeColor")
if self.tc == nil self.tc = self.fg end
self.tall = height() > 8
self.ic = "data:image/gif;base64,R0lGODlhCAAIAIQAAAAAAAAAAJwCBLwCBMRyBNxWHOxaHPT+JPwCBPwaHPxeLPx6HPyGBPyODPySBPyWPPyaDPyeHPyiHPymHPyyHPyyJPy2BPy2DPy6HPy+DPy+FPzCFPzSBPzyBAAAAAAAACH5BAUKAAAALAAAAAAGAAgAAAUZICAiYomQ4zkqSnIWEaWc0XGcSHFEKEKhIQAh+QQFCgAAACwBAAEABgAGAAAFEGACjGSJjJGCHiUZkdRRjCEAIfkEBQoAAAAsAAAAAAcABwAABRYgAowkEIgBkJRjOirrWGAaO4rkEeEhACH5BAUKAAAALAAAAAAHAAYAAAUUYAAg4miWIgIApbqyQBEdivtObwgAIfkEBQoAAAAsAQAAAAYABwAABREgEADkSJ5oeh5SU6DSGb9kCAAh+QQFCgAAACwAAAEABQAHAAAFFSAQAAhgmiXwoI91KIABTGYBRCdhhgAh+QQFCgAAACwAAAAABQAIAAAFESAgImJpAsFZAIcjrtFZxkAIACH5BAUKAAAALAAAAgAGAAYAAAUPICACyAgsZLkcI2q+oguEACH5BAUKAAAALAAAAQAFAAYAAAUQIAAEACKeJLCdq1iIFbCcIQAh+QQFCgAAACwBAAIAAQABAAAFA2AQAgAh+QQFCgAAACwCAAIAAgAGAAAFCiBQAQdgdkBRACEAIfkEBQoAAAAsAQAAAAUABgAABRAgACSJWIlot5TnCizniAIhACH5BAUKAAAALAAAAQAGAAcAAAUTIAAU3FGIIocCixigXHuya52gIQAh+QQFCgAAACwAAAAABwAGAAAFFCAgAscyJuKCpuNYAC+QFCYarGsIACH5BAUKAAAALAIAAAAFAAgAAAUUIBAAXBIsACQiKAK8ryrCMwoLdAgAIfkEBQoAAAAsAAAAAAcACAAABRsgIALQkY3IMoqBAARAgrDjdQFziooMd6+FVQgAIfkEBQoAAAAsAAAAAAcACAAABRcgIAIBsIxBUgAJgIxwbMpiNl4HF79jCAAh+QQFCgAAACwAAAAABwAHAAAFFiAgikmRjIGYAkkgjMXCkQB3jPiV4yEAIfkEBQoAAAAsAAAAAAcABwAABRRgAoxjEpCAMKDASXILWbBARh9sCAAh+QQFCgAAACwBAAAABgAHAAAFFCAgAsIgIkAQjGxysmMBHJmYcWwIACH5BAUKAAAALAIAAAAFAAcAAAUQIIAAQTACKHoCSwpwrnu4IQA7"
if !store.get("showicon") self.ic = nil end
self.io = self.tall ? 4 : 0
self.pc = self.ic == nil ? [["--", 0], [":", 0], ["--", 0], [":", 0], ["--", 0]] : [["--", 0], [":", 0], ["--", 0]]
self.hm = [["--", 0], [":", 0], ["--", 0]]           # the quiet hours' HH:MM
self.cells = nil
self.cq = false
self.qnow = false
self.shown = false
self.sec = -1
self.sep = "pulse"
self.wk = store.get("weekday")
self.monday = store.get("monday")
self.today = store.get("today")
self.other = store.get("other")
self.font2 = [[3, 0, 7, 5, 5, 5, 7], [3, 0, 2, 6, 2, 2, 7], [3, 0, 7, 1, 7, 4, 7], [3, 0, 7, 1, 7, 1, 7],
[3, 0, 5, 5, 7, 1, 1], [3, 0, 7, 4, 7, 1, 7], [3, 0, 7, 4, 7, 5, 7], [3, 0, 7, 1, 1, 1, 1],
[3, 0, 7, 5, 7, 5, 7], [3, 0, 7, 5, 7, 1, 7], [1, 1, 1, 0, 1], [3, 2, 7]]
end
def quiet()
if !store.get("quiet") || epoch_ms() < 0 return false end
var h = hour()
var f = int(store.get("qfrom"))
var t = int(store.get("qto"))
return f > t ? (h >= f || h < t) : (h >= f && h < t)
end
def dim()
var saved = store.get("bright", -1)
if self.qnow && self.shown
if saved < 0
store.set("bright", settings.get("brightness"))
store.set("auto", settings.get("autoBrightness") == true)
settings.set("autoBrightness", false)
settings.set("brightness", max(1, int(int(store.get("qdim")) * 255 / 100.0 + 0.5)))
end
elif saved >= 0
settings.set("brightness", saved)
if store.get("auto", false) settings.set("autoBrightness", true) end
store.set("bright", -1)
end
end
def loop()
self.qnow = self.quiet()
self.dim()
end
def on_show()
self.shown = true
self.qnow = self.quiet()
self.dim()
end
def on_hide()
self.shown = false
self.dim()
end
def draw()
clear()
var h = height()
var q = self.qnow
var x0 = 0
var aw = width()
if self.ic != nil && !q
x0 = self.tall ? 17 : 9
aw = self.tall ? 34 : width() - 9
icon(self.ic, self.io, self.io)
end
var pc = q ? self.hm : self.pc
var s = second()
if s >= 0 && s != self.sec
self.sec = s
self.sep = settings.get("timeSeparatorMode")
var hr = hour()
if settings.get("time24h") == false hr = hr % 12 == 0 ? 12 : hr % 12 end
var all = self.pc
all[0][0] = settings.get("timeLeadingZero") == false ? str(hr) : string.format("%02d", hr)
all[2][0] = string.format("%02d", minute())
if size(all) > 3 all[4][0] = string.format("%02d", s) end
self.hm[0][0] = all[0][0]
self.hm[2][0] = all[2][0]
self.cells = nil
end
if self.tall && (self.cells == nil || self.cq != q)
self.cq = q
self.cells = []
for p : pc
var i = 0
while i < size(p[0])
self.cells.push([string.find("0123456789:-", p[0][i]), 0])
i += 1
end
end
end
var c = self.tc
var lvl = 1.0
if self.sep == "blink"
lvl = s % 2 ? 0.0 : 1.0
elif self.sep == "pulse"
lvl = 0.5 * (1 - math.cos(2 * math.pi * (now_ms() % 2000) / 2000.0))
end
var cc = rgb(int(((c >> 16) & 255) * lvl + 0.5), int(((c >> 8) & 255) * lvl + 0.5), int((c & 255) * lvl + 0.5))
var bar = !q && self.wk && weekday() >= 0
var j = 0
if self.tall
var cells = self.cells
while j < size(cells)
cells[j][1] = cells[j][0] == 10 ? cc : c
j += 1
end
var cg = size(pc) > 3 ? 1 : 2
var tw = self.big(cells, 0, 0, cg, false)
self.big(cells, x0 + (aw - tw) / 2, bar ? 2 : 3, cg, true)
else
while j < size(pc)
pc[j][1] = j % 2 == 1 ? cc : c
j += 1
end
font("small")
text(x0 + max(0, (aw - text_ink_width(pc)) / 2), 6, pc)
end
if bar
var sw = self.tall ? 4 : (self.ic != nil ? 2 : 3)
var bx = x0 + max(0, (aw - 7 * sw - 6) / 2)
var today = self.monday ? (weekday() + 6) % 7 : weekday()
j = 0
while j < 7
rect_fill(bx + j * (sw + 1), h - 1, sw, 1, j == today ? self.today : self.other)
j += 1
end
end
end
def big(cells, x, y, cg, d)
var w = 0
var n = size(cells)
var i = 0
while i < n
var g = self.font2[cells[i][0]]
if d
var r = 2
while r < size(g)
var b = 0
while b < g[0]
if g[r] & (1 << (g[0] - 1 - b)) rect_fill(x + w + b * 2, y + (g[1] + r - 2) * 2, 2, 2, cells[i][1]) end
b += 1
end
r += 1
end
end
w += g[0] * 2
if i + 1 < n w += cells[i][0] == 10 || cells[i + 1][0] == 10 ? cg : 2 end
i += 1
end
return w
end
end
return Clock()
