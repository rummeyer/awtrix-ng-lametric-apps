# @name    Weather
# @desc    The sky and temperature, the day's low and high, humidity and wind from Open-Meteo, as LaMetric's Weather
# @author  Oliver Rummeyer
# @version 2.0
# @config  lat     text   "Latitude"       default="52.52"
# @config  lon     text   "Longitude"      default="13.40"
# @config  page    number "Each page"      default=5 min=2 max=30 unit=s help="How long each of the four pages stays"
# @config  wind    select "Wind in"        default=km/h options=km/h,m/s,mph,kn
# @config  every   number "Update every"   default=15 min=5 max=60 unit=min
# @config  overlay bool   "Rain and snow"  default=false help="The clock's rain, snow and thunder over the pages"
# @config  quiet   bool   "Quiet hours"    default=false group="Quiet hours" help="Left out of the rotation between these hours; the weather keeps coming"
# @config  qfrom   number "From"           default=23 min=0 max=23 unit=h group="Quiet hours"
# @config  qto     number "To"             default=8 min=0 max=23 unit=h group="Quiet hours"
import string

# The weather from Open-Meteo, as LaMetric's Weather and with LaMetric's icons, a page each: the
# sky with the temperature, a thermometer with the day's low and high, a drop with the humidity,
# and a windsock with the wind speed giving way to where it comes from. The icons are installed on
# the clock by install-icons.py and drawn at their 8×8, 16 rows high, as on the TC002, in the
# middle of the 16×16 square, with text at twice its size, as the clock draws its own apps there;
# 8 rows high, as on the TC001, at the left edge with the small font. The pages slide down one after
# the other.
class Weather
  var fg, tall, font2, unit, deg, url, wx, wat, fx, sky, slots, t0, ticks, busy

  def init()
    self.fg = settings.get("textColor")
    if self.fg == nil self.fg = 0xFFFFFF end
    self.tall = height() > 8
    # The clock's small font for big(), the characters of "0123456789:-'%/NESWCF" (' the degree):
    # ink width, rows from the cap top, then a row per number, the leftmost pixel the highest bit.
    self.font2 = [[3, 0, 7, 5, 5, 5, 7], [3, 0, 2, 6, 2, 2, 7], [3, 0, 7, 1, 7, 4, 7], [3, 0, 7, 1, 7, 1, 7],
                  [3, 0, 5, 5, 7, 1, 1], [3, 0, 7, 4, 7, 1, 7], [3, 0, 7, 4, 7, 5, 7], [3, 0, 7, 1, 1, 1, 1],
                  [3, 0, 7, 5, 7, 5, 7], [3, 0, 7, 5, 7, 1, 7], [1, 1, 1, 0, 1], [3, 2, 7], [2, 0, 3, 3],
                  [3, 0, 5, 1, 2, 4, 5], [3, 0, 1, 1, 2, 4, 4], [4, 0, 9, 13, 11, 9, 9], [3, 0, 7, 4, 7, 4, 7],
                  [3, 0, 7, 4, 7, 1, 7], [5, 0, 17, 17, 17, 21, 10], [3, 0, 2, 5, 4, 5, 2], [3, 0, 7, 4, 7, 4, 4]]
    # Open-Meteo, no key needed: the current weather and the day's low and high
    var units = {"km/h": "kmh", "m/s": "ms", "mph": "mph", "kn": "kn"}
    self.unit = store.get("wind")
    self.deg = "C"
    var lat = re.search("-?[0-9]+[.,]?[0-9]*", str(store.get("lat")))
    var lon = re.search("-?[0-9]+[.,]?[0-9]*", str(store.get("lon")))
    self.url = nil
    if lat != nil && lon != nil
      self.url = "https://api.open-meteo.com/v1/forecast?latitude=" + string.replace(lat[0], ",", ".") +
                 "&longitude=" + string.replace(lon[0], ",", ".") +
                 "&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m,wind_direction_10m" +
                 "&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto" +
                 "&wind_speed_unit=" + units.find(self.unit, "kmh")
      if settings.get("useCelsius") == false
        self.url += "&temperature_unit=fahrenheit"
        self.deg = "F"
      end
    end
    # The last weather survives a restart, so it shows before the first answer.
    self.wx = store.get("wx")
    if !isinstance(self.wx, list) || size(self.wx) != 8 self.wx = nil end
    self.wat = now_ms()
    self.slots = nil
    self.fx = nil
    self.sky = "2283"
    if self.wx != nil self.build() end
    self.t0 = 0
    self.ticks = 0
    self.busy = false
  end

  # The weather every few minutes, again in a minute when it did not come.
  def loop()
    if self.url == nil || self.busy return end
    self.ticks -= 1
    if self.ticks > 0 return end
    self.ticks = int(store.get("every")) * 60
    self.busy = true
    http.get(self.url, / b, s -> self.on_weather(b, s), {'find': '"current":{', 'keep': 400})
  end

  # From "current" on: temperature, humidity, day or night, the WMO weather code, wind speed and
  # where it comes from, then the day's high and low.
  def on_weather(body, status)
    self.busy = false
    var v = []
    if status == 200 && body != nil
      for k : ["temperature_2m", "relative_humidity_2m", "is_day", "weather_code", "wind_speed_10m",
               "wind_direction_10m", "temperature_2m_max", "temperature_2m_min"]
        var m = re.search('"' + k + '":\\[?(-?[0-9.]+)', body)
        if m == nil break end
        v.push(real(m[1]))
      end
    end
    if size(v) != 8
      self.ticks = 60
      return
    end
    self.wx = v
    self.wat = now_ms()
    store.set("wx", v)
    self.build()
  end

  # What the pages show, worked out once, never in draw(): the sky's icon and overlay, and for each
  # page the first and second half (nil for none), each a list of ways to write it, the first that
  # fits is drawn: [0, cells] at twice the size, [1, pieces] in the small font, or [2, cells, unit]
  # with the unit small beside them.
  def build()
    var v = self.wx
    var day = v[2] > 0
    var code = int(v[3])
    self.fx = nil
    # The sky as LaMetric's icon: sunny or night, partly cloudy by day or night, cloudy, fog, rain,
    # snow and thunder
    if code <= 1 self.sky = day ? "2282" : "2285"
    elif code == 2 self.sky = day ? "2286" : "12195"
    elif code == 3 self.sky = "2283"
    elif code < 50 self.sky = "17056"
    elif code < 60 self.sky = "2284" self.fx = "drizzle"
    elif code < 70 || (code >= 80 && code < 85) self.sky = "2284" self.fx = "rain"
    elif code < 90 self.sky = "2289" self.fx = "snow"
    else self.sky = "2288" self.fx = "thunder"
    end
    var B = 0x2E9BFF
    var R = 0xFF3020
    var fg = self.fg
    var tc = settings.get("temperatureColor")
    if tc == nil tc = fg end
    var d = self.deg
    var t = str(round(v[0]))
    var h = str(round(v[1]))
    var w = str(round(v[4]))
    var hi = str(round(v[6]))
    var lo = str(round(v[7]))
    var dir = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][(int(v[5]) * 2 + 45) / 90 % 8]
    # The day's low and high in one line where it fits at twice the size, else 16 rows high the low
    # and then the high, each at twice the size; 8 rows high one line in the small font.
    var both = self.cells(lo + "'" + d + "/", B) + self.cells(hi + "'" + d, R)
    var minmax = [[[1, [[lo + "°" + d, B], ["/", fg], [hi + "°" + d, R]]],
                   [1, [[lo + "°", B], ["/", fg], [hi + "°" + d, R]]],
                   [1, [[lo, B], ["/", fg], [hi + "°" + d, R]]],
                   [1, [[lo, B], ["/", fg], [hi, R]]]], nil]
    if self.tall
      minmax = self.big(both, 0, 0, false) <= width() - 18 ? [[[0, both]], nil] :
               [[[0, self.cells(lo + "'" + d, B)], [0, self.cells(lo + "'", B)], [1, [[lo + "°" + d, B]]]],
                [[0, self.cells(hi + "'" + d, R)], [0, self.cells(hi + "'", R)], [1, [[hi + "°" + d, R]]]]]
    end
    self.slots = [
      [[[0, self.cells(t + "'" + d, tc)], [0, self.cells(t + "'", tc)], [1, [[t + "°" + d, tc]]], [1, [[t + "°", tc]]]], nil],
      minmax,
      [[[0, self.cells(h + "%", fg)], [1, [[h + "%", fg]]]], nil],
      [[[2, self.cells(w, fg), self.unit], [0, self.cells(w, fg)], [1, [[w + self.unit, fg]]], [1, [[w, fg]]]],
       [[0, self.cells(dir, fg)], [1, [[dir, fg]]]]]]
  end

  # A string of "0123456789:-'%/NESWCF" as cells for big(), all in colour c.
  def cells(s, c)
    var out = []
    var i = 0
    while i < size(s)
      out.push([string.find("0123456789:-'%/NESWCF", s[i]), c])
      i += 1
    end
    return out
  end

  # Within the quiet hours from the settings, across midnight too; never before the clock knows the time.
  def quiet()
    if !store.get("quiet") || epoch_ms() < 0 return false end
    var h = hour()
    var f = int(store.get("qfrom"))
    var t = int(store.get("qto"))
    return f > t ? (h >= f || h < t) : (h >= f && h < t)
  end

  # Nothing to show in the quiet hours, before the first weather, or when it is more than three
  # hours old.
  def should_show()
    return !self.quiet() && self.slots != nil && now_ms() - self.wat < 10800000
  end

  def duration()
    return int(store.get("page")) * 4000
  end

  def on_show()
    self.t0 = now_ms()
  end

  def draw()
    clear()
    if self.slots == nil
      font("small")
      text((width() - text_ink_width("...")) / 2, self.tall ? 10 : 6, "...", 0x666666)
      return
    end
    # The rotation keeps the app a moment past its time: the last page stays rather than the first
    # coming back for it. Kept on longer, as the only app, it rounds again from the sky.
    var ms = int(store.get("page")) * 1000
    var t = now_ms() - self.t0
    var el = t % (4 * ms + 3000)
    if el >= 4 * ms el = 4 * ms - 1 end
    var i = el / ms
    var ph = el - i * ms
    var h = height()
    var p = i > 0 ? i - 1 : (t > 4 * ms ? 3 : i)
    if p != i && ph < 300
      var dy = ph * h / 300 - h                    # the new page in from the top, the old out at the bottom
      self.show(p, dy + h, ms - 1, ms)
      self.show(i, dy, 0, ms)
    else
      self.show(i, 0, ph, ms)
      if self.fx != nil && store.get("overlay") overlay(self.fx) end
    end
  end

  # Page k, dy rows down, ph of its ms in: its icon, and what it shows. A page with two halves
  # slides the first down out of sight in its last 0.4 s, and the second down in from the top in
  # its first.
  def show(k, dy, ph, ms)
    var two = self.slots[k]
    # Halfway through what is left once the page has slid in, so both halves stay as long
    var half = (ms + 300) / 2
    var second = two[1] != nil && ph >= half
    # The page's icon: the sky; the thermometer, cold with the low and warm with the high; the drop;
    # the windsock.
    var o = self.tall ? 4 : 0
    icon(k == 0 ? self.sky : (k == 1 ? (two[1] != nil && !second ? "21686" : "21685") : (k == 2 ? "1167" : "3363")), o, dy + o)
    var into = second ? ph - half : ph
    var off = 0
    var rows = self.tall ? 16 : 8
    if !second && two[1] != nil && half - into < 400
      off = (400 - (half - into)) * (rows + 1) / 400
    elif second && into < 400
      off = into * rows / 400 - rows
    end
    var ways = two[second ? 1 : 0]
    var x0 = self.tall ? 18 : 9
    # The wind's direction in the middle of what is left beside the 8×8 icon
    if self.tall && k == 3 && second x0 = 12 end
    var aw = width() - x0
    var y = dy + off
    font("small")
    var j = 0
    while j < size(ways)
      var w = ways[j]
      var last = j == size(ways) - 1
      if w[0] == 1
        var tw = text_ink_width(w[1])
        if tw <= aw || last
          text(x0 + max(0, (aw - tw) / 2), y + (self.tall ? 10 : 6), w[1], self.fg)
          return
        end
      elif self.tall
        var bw = self.big(w[1], 0, 0, false)
        var uw = w[0] == 2 ? text_ink_width(w[2]) + 2 : 0
        if bw + uw <= aw
          var x = x0 + (aw - bw - uw) / 2
          self.big(w[1], x, y + 3, true)
          if uw > 0 text(x + bw + 2, y + 13, w[2], 0x909090) end
          return
        end
      end
      j += 1
    end
  end

  # Cells of the small font at twice its size from x, its cap top at y, 2 columns apart. Draws them
  # when d is true; answers the width either way.
  def big(cells, x, y, d)
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
      w += g[0] * 2 + (i + 1 < n ? 2 : 0)
      i += 1
    end
    return w
  end
end
return Weather()
