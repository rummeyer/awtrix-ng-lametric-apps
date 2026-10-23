# @name    Clock
# @desc    The time beside LaMetric's flame with the weekday under it, as LaMetric's Alarm Clock
# @author  Oliver Rummeyer
# @version 2.3
# @config  showicon bool  "Icon"           default=true help="LaMetric's flame beside the time; off shows the time with seconds"
# @config  weekday bool   "Weekday"        default=true help="The days of the week under the time"
# @config  monday  bool   "Week starts Monday" default=true group="Weekday"
# @config  today   color  "Today"          default=#FFFFFF group="Weekday"
# @config  other   color  "Other days"     default=#666666 group="Weekday"
# @config  quiet   bool   "Quiet hours"    default=false group="Quiet hours" help="Only the time, without the flame and the weekday, and the display dimmed between these hours"
# @config  qfrom   number "From"           default=23 min=0 max=23 unit=h group="Quiet hours"
# @config  qto     number "To"             default=8 min=0 max=23 unit=h group="Quiet hours"
# @config  qdim    slider "Brightness"     default=1 min=0 max=100 unit=% group="Quiet hours" help="Of the whole display in the quiet hours; the old one comes back after them"
import string
import math

# The time beside LaMetric's flame, 7756, with the days of the week under it, as LaMetric's Alarm
# Clock, laid out as the clock's own Time app: 16 rows high, as the TC002's, the small font at twice
# its size beside the icon where the Time app has its calendar sheet; 8 rows high, as the TC001's,
# the small font beside it. Without the icon the time with seconds across the display. 24 or 12 hours,
# leading zero and the colon follow the clock's time settings. The time always in the middle of
# what is left beside the icon. In the quiet hours only HH:MM in the middle of the display, and the
# display dimmed while it is shown.
class Clock
  var fg, tc, ic, io, tall, pc, hm, cells, cq, qnow, shown, sec, sep, font, wk, monday, today, other

  def init()
    self.fg = settings.get("textColor")
    if self.fg == nil self.fg = 0xFFFFFF end
    self.tc = settings.get("timeColor")
    if self.tc == nil self.tc = self.fg end
    self.tall = height() > 8
    # The icon comes with the script, as small as a GIF goes while it plays the same; literals side by
    # side are one string, so it is held once. 16 rows high at its 8×8 in the middle of the square.
    self.ic = "data:image/gif;base64,R0lGODlhCAAIAIQAAAAAAAAAAJwCBLwCBMRyBNxWHOxaHPT+JPwCBPwaHPxeLPx6HP"
              "yGBPyODPySBPyWPPyaDPyeHPyiHPymHPyyHPyyJPy2BPy2DPy6HPy+DPy+FPzCFPzSBPzyBAAAAAAAACH5BAUKAA"
              "AALAAAAAAGAAgAAAUZICAiYomQ4zkqSnIWEaWc0XGcSHFEKEKhIQAh+QQFCgAAACwBAAEABgAGAAAFEGACjGSJjJ"
              "GCHiUZkdRRjCEAIfkEBQoAAAAsAAAAAAcABwAABRYgAowkEIgBkJRjOirrWGAaO4rkEeEhACH5BAUKAAAALAAAAA"
              "AHAAYAAAUUYAAg4miWIgIApbqyQBEdivtObwgAIfkEBQoAAAAsAQAAAAYABwAABREgEADkSJ5oeh5SU6DSGb9kCA"
              "Ah+QQFCgAAACwAAAEABQAHAAAFFSAQAAhgmiXwoI91KIABTGYBRCdhhgAh+QQFCgAAACwAAAAABQAIAAAFESAgIm"
              "JpAsFZAIcjrtFZxkAIACH5BAUKAAAALAAAAgAGAAYAAAUPICACyAgsZLkcI2q+oguEACH5BAUKAAAALAAAAQAFAA"
              "YAAAUQIAAEACKeJLCdq1iIFbCcIQAh+QQFCgAAACwBAAIAAQABAAAFA2AQAgAh+QQFCgAAACwCAAIAAgAGAAAFCi"
              "BQAQdgdkBRACEAIfkEBQoAAAAsAQAAAAUABgAABRAgACSJWIlot5TnCizniAIhACH5BAUKAAAALAAAAQAGAAcAAA"
              "UTIAAU3FGIIocCixigXHuya52gIQAh+QQFCgAAACwAAAAABwAGAAAFFCAgAscyJuKCpuNYAC+QFCYarGsIACH5BA"
              "UKAAAALAIAAAAFAAgAAAUUIBAAXBIsACQiKAK8ryrCMwoLdAgAIfkEBQoAAAAsAAAAAAcACAAABRsgIALQkY3IMo"
              "qBAARAgrDjdQFziooMd6+FVQgAIfkEBQoAAAAsAAAAAAcACAAABRcgIAIBsIxBUgAJgIxwbMpiNl4HF79jCAAh+Q"
              "QFCgAAACwAAAAABwAHAAAFFiAgikmRjIGYAkkgjMXCkQB3jPiV4yEAIfkEBQoAAAAsAAAAAAcABwAABRRgAoxjEp"
              "CAMKDASXILWbBARh9sCAAh+QQFCgAAACwBAAAABgAHAAAFFCAgAsIgIkAQjGxysmMBHJmYcWwIACH5BAUKAAAALA"
              "IAAAAFAAcAAAUQIIAAQTACKHoCSwpwrnu4IQA7"
    if !store.get("showicon") self.ic = nil end
    self.io = self.tall ? 4 : 0
    # The time in pieces for text(), and 16 rows high as cells for big(); dashes until the clock
    # knows the time.
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
    # The clock's small font for big(), the characters of "0123456789:-", a number each: the ink
    # width in the lowest 3 bits, then 5 rows of 5 bits from the cap top, the leftmost pixel the
    # highest bit.
    self.font = [60073275, 59262483, 59826491, 59040059, 8709419, 59040827, 60089403, 8659259, 60089659,
                 59041083, 262401, 57347]
  end

  # Within the quiet hours from the settings, across midnight too; never before the clock knows the time.
  def quiet()
    if !store.get("quiet") || epoch_ms() < 0 return false end
    var h = hour()
    var f = int(store.get("qfrom"))
    var t = int(store.get("qto"))
    return f > t ? (h >= f || h < t) : (h >= f && h < t)
  end

  # The display's brightness in the quiet hours: dimmed while the Clock is on screen, the old one
  # kept in the store and back as soon as the next app comes, even across a restart in between.
  # Outside the quiet hours the day's brightness is kept too: a restart that kept the dimmed display
  # but lost the store would otherwise leave the dimmed one as the old one, for good.
  def dim()
    var saved = store.get("bright", -1)
    var lvl = max(1, int(int(store.get("qdim")) * 255 / 100.0 + 0.5))
    var b = settings.get("brightness")
    if self.qnow && self.shown
      if saved < 0
        if b == lvl b = store.get("day", b) end
        store.set("bright", b)
        store.set("auto", settings.get("autoBrightness") == true)
        settings.set("autoBrightness", false)
        settings.set("brightness", lvl)
      end
    elif saved >= 0
      settings.set("brightness", saved)
      if store.get("auto", false) settings.set("autoBrightness", true) end
      store.set("bright", -1)
    elif !self.qnow && b != lvl && b != store.get("day")
      store.set("day", b)
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
      # Everything right of the icon's square, 16 columns 16 rows high; else right of the 8×8 icon and
      # a dark column, so the two never touch
      x0 = self.tall ? 16 : 9
      aw = width() - x0
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
      # "0123456789:-" by position; the cells' colours are set below, frame by frame
      self.cells = []
      for p : pc
        var i = 0
        while i < size(p[0])
          self.cells.push([string.find("0123456789:-", p[0][i]), 0])
          i += 1
        end
      end
    end
    # The colon as the clock's separator setting has it: steady, blinking or pulsing
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
      # With seconds a narrower gap at the colons, as the Time app's big face
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
      # Seven bars a row high along the bottom, a column apart: 4 wide 16 rows high, else 2 beside an
      # icon and 3 without.
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

  # Cells of the small font at twice its size from x, its cap top at y: a gap of 2 between them,
  # cg either side of a colon. Draws them when d is true; answers the width either way.
  def big(cells, x, y, cg, d)
    var w = 0
    var n = size(cells)
    var i = 0
    while i < n
      var g = self.font[cells[i][0]]
      var gw = g & 7
      if d
        var r = 0
        while r < 5
          var bits = (g >> (3 + 5 * r)) & 31
          var b = 0
          while bits != 0 && b < gw
            if bits & (1 << (gw - 1 - b)) rect_fill(x + w + b * 2, y + r * 2, 2, 2, cells[i][1]) end
            b += 1
          end
          r += 1
        end
      end
      w += gw * 2
      if i + 1 < n w += cells[i][0] == 10 || cells[i + 1][0] == 10 ? cg : 2 end
      i += 1
    end
    return w
  end
end
return Clock()
