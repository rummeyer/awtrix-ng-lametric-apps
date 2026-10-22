# @name    Weather
# @desc    The sky and temperature, the day's low and high, humidity and wind from Open-Meteo, as LaMetric's Weather
# @author  Oliver Rummeyer
# @version 2.1
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
# and a windsock with the wind speed giving way to where it comes from. The icons come with the
# script and are drawn at their 8×8, 16 rows high, as on the TC002, in the middle of the 16×16
# square, with text at twice its size, as the clock draws its own apps there; 8 rows high, as on
# the TC001, at the left edge with the small font. The pages slide down one after
# the other.
class Weather
  var fg, tall, font, gif, unit, deg, url, wx, wat, fx, sky, slots, t0, ticks, busy

  def init()
    self.fg = settings.get("textColor")
    if self.fg == nil self.fg = 0xFFFFFF end
    self.tall = height() > 8
    # The clock's small font for big(), the characters of "0123456789:-'%/NESWCF" (' the degree), a
    # number each: the ink width in the lowest 3 bits, then 5 rows of 5 bits from the cap top, the
    # leftmost pixel the highest bit.
    self.font = [60073275, 59262483, 59826491, 59040059, 8709419, 59040827, 60089403, 8659259, 60089659,
                 59041083, 262401, 57347, 794, 43008299, 34619659, 77950284, 59827259, 59040827, 89534861,
                 18122003, 34661435]
    # LaMetric's icons by their number, made as small as GIFs go while they play the same: one
    # colour table, identical frames merged, each frame only what changed. Literals side by side are
    # one string, so each is held once.
    self.gif = {
      # 2282 sunny
      "2282": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAExGBKSeBMzCBPz2BPz2lPz61CH5BAUCAAAALAAAAA"
              "AIAAgAAAMaCCBEoqCV0haZ5biLp5zHNDCh90gaATGOkgAAIfkEBQoAAAAsAgABAAQABgAAAwkIB8ylbL0HwUsAIf"
              "kEBQoAAAAsAQADAAYAAwAAAwh4UABaqskFEgAh+QQFCgAAACwBAAEABgAGAAADCwhQqtcLvBjnhDcBACH5BAUKAA"
              "AALAEAAQAFAAYAAAMLCHAKtfA19SQDhiUAIfkEBQoAAAAsAQADAAQABAAAAwhYsMfQC5SSAAAh+QQFCgAAACwBAA"
              "EABgAGAAADCwhQ2v7rLCDZVFIlADs=",
      # 2285 night
      "2285": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAAQCFAQCHAQCLAQCNAQCRAQCVAQCZCwuLGxubLS2tP"
              "z+/AAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQYUMhJ6xrjYky670UohkZplkeqpgiytHAEACH5BAUKAAAALA"
              "AAAAAIAAgAAAQPEMiZQJ1SZcy7pZ8namEEACH5BAUKAAAALAAAAAAIAAgAAAQPEMipQJ0yZcy7pZ8namEEACH5BA"
              "UKAAAALAAAAAAIAAgAAAQQEMi5QJ1SyIG7txT4jYh0RQAh+QQFCgAAACwAAAAACAAIAAAEEBDIyUCdMmVMsJeXJX"
              "7kNkYAIfkEBQoAAAAsAAAAAAgACAAABBIQyLlAnVJlPLCXlyV+kvFpYwQAIfkEBQoAAAAsAAAAAAgACAAABBMQyJ"
              "lAnZJlTLCXlyV+0jEZ2xgBADs=",
      # 2286 partly cloudy
      "2286": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAERCRFRWBGxSBGxubKSipMS+BMTGxOTm5Pz6BAAAAA"
              "AAAAAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQeEIBxzpCgKiXE7FySdAgilKWhrqpQvLDXzZ5EWVIEACH5BA"
              "UKAAAALAAAAQAIAAYAAAQTEEh5gABVqJvORRc1jUM4FdhoRQAh+QQFCgAAACwBAAEABgAGAAAEEBBIeYACQmUBEL"
              "8TcHBhNUUAIfkEBQoAAAAsAgABAAYABgAABBAQSBmAAuIIJQDq12R1YihFACH5BAUKAAAALAMAAgAFAAUAAAQNEC"
              "ggghIAiQn67R4YAQAh+QQFCgAAACwEAAIABAAFAAAECxAoIJQAaAJ599kRACH5BAUKAAAALAUAAgACAAUAAAQHEB"
              "wlFKAyAgAh+QQFCgAAACwGAAIAAgAFAAAECBAMJRQ4ApAIACH5BAUKAAAALAcAAwABAAQAAAQE8JwRIgAh+QQFCg"
              "AAACwAAAIAAQAEAAAEBFAgIyIAIfkEBQoAAAAsAAABAAIABgAABAhQgCQRMEXICAAh+QQFCgAAACwBAAEAAgAGAA"
              "AECFCAJBEwRcgIACH5BAUKAAAALAAAAQAEAAYAAAQNMAAxQaIAoAxMLhgVAQAh+QQFCgAAACwAAAEABQAGAAAEDx"
              "AEIGRNogKA9jZeoVFABAAh+QQFCgAAACwAAAEABgAGAAAEETCcIwSlKQm0kTdgWIxjZVoRACH5BAUKAAAALAEAAQ"
              "AGAAYAAAQSEAAFRFU2CWQlkqABAkUnCUEEADs=",
      # 12195 partly cloudy at night
      "12195": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAERGRISGhMzOzPz+/AAAAAAAACH5BAUKAAAALAAAAA"
               "AIAAgAAAMVCFqq842BUmCUbdK46MDAIwyNOA4JACH5BAUKAAAALAYAAQABAAEAAAMCSAkAIfkEBQoAAAAsBgABAA"
               "EAAQAAAwJYCQAh+QQFCgAAACwGAAEAAQABAAADAkgJACH5BAUKAAAALAYAAQABAAEAAAMCWAkAIfkEBQoAAAAsBg"
               "ABAAEAAQAAAwJICQA7",
      # 2283 cloudy
      "2283": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAERCRGxubKSipMTGxOTm5AAAACH5BAUKAAAALAAAAQ"
              "AIAAYAAAMTCKoi7MKYVoqoleitxfgg1IxAAgAh+QQFCgAAACwAAAEACAAGAAADEQiqAQJNhGcmKI+tbfeAm5MAAC"
              "H5BAUKAAAALAEAAQAGAAYAAAMNCKoBLQEKUGZbbuKrEgAh+QQFCgAAACwCAAEABgAGAAADDQiqAS0BClBmW27iqx"
              "IAIfkEBQoAAAAsAwACAAUABQAAAwsIARIhoDRAFayLJgAh+QQFCgAAACwEAAIABAAFAAADCQgBEgJlAfWmTAAh+Q"
              "QFCgAAACwFAAIAAgAFAAADBggREioqAQAh+QQFCgAAACwGAAIAAgAFAAADBggREioqAQAh+QQFCgAAACwHAAMAAQ"
              "ADAAADAhiaACH5BAUKAAAALAAAAgABAAQAAAMDKEWSACH5BAUKAAAALAAAAQACAAYAAAMHKGBaQEOoBAAh+QQFCg"
              "AAACwBAAEAAgAGAAADByhgWkBDqAQAIfkEBQoAAAAsAAABAAQABgAAAwsYIAvGAJQISByQJQAh+QQFCgAAACwAAA"
              "EABQAGAAADDQgBom2iAVDmJHZIBhIAIfkEBQoAAAAsAAABAAYABgAAAw8IECAdzojiVFGYYDCqcgkAIfkEBQoAAA"
              "AsAQABAAYABgAAAw8IECAdzojiVFGYYDCqcgkAOw==",
      # 17056 fog
      "17056": "data:image/gif;base64,R0lGODlhCAAIAIEAAAAAAAAAAMzOzAAAACH5BAUyAAAALAAAAQAIAAUAAAIJhH6gy2"
               "jOIkoFACH5BAUyAAAALAEAAQAGAAUAAAIIDA6Cm8anUCgAOw==",
      # 2284 rainy
      "2284": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAACRCzERCRERSjGxubKSipMTGxOTm5AAAAAAAAAAAAA"
              "AAAAAAAAAAAAAAACH5BAUUAAAALAAAAAAIAAgAAAQbEEg5BrUDoXrO6J0hjuJQnKglVKswvTAByEAEACH5BAUUAA"
              "AALAEABQAGAAMAAAQJkIwhiQjhXswjACH5BAUUAAAALAEABQAGAAMAAAQKcAAxKAHgEoG5iAAh+QQFFAAAACwBAA"
              "UABgADAAAEChAAMkEAImRaSQQAIfkEBRQAAAAsAQAFAAYAAwAABAlwyBkCsTUIHSIAOw==",
      # 2289 snowy
      "2289": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAERCRGxubKSipMTGxOTm5AAAACH5BAUKAAAALAAAAA"
              "AIAAgAAAMXCKoi7MKYVoqoleitxfgg1IxLuRgKqiQAIfkEBQoAAAAsAQAFAAYAAwAAAwdoImrxML4EACH5BAUKAA"
              "AALAEABQAGAAIAAAMGKAAqts8kACH5BAUKAAAALAEABQAGAAMAAAMIaLAa60EBZRIAIfkEBQoAAAAsAQAFAAYAAw"
              "AAAwcouhbeLoYEACH5BAUKAAAALAEABQAGAAMAAAMICGBqoeCxBhIAIfkEBQoAAAAsAQAFAAYAAwAAAwcouhHWr8"
              "kEACH5BAUKAAAALAEABQAGAAMAAAMIaAC6EAuyZRIAIfkEBQoAAAAsAQAFAAYAAwAAAwcouhbRLroEADs=",
      # 2288 stormy
      "2288": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAADQyNERCRGxqbIRyRKyurMTGxNSqLPzSBAAAAAAAAA"
              "AAAAAAAAAAAAAAACH5BAUyAAAALAAAAAAIAAYAAAQWEEgpBLXinGqM6B0hjmI1COcJVKwVAQAh+QQFAgAAACwEAA"
              "MAAQABAAAEArBEACH5BAUCAAAALAMAAwAEAAIAAAQHECAAihgiAgAh+QQFAgAAACwCAAMAAwADAAAEBxCABBAoMg"
              "IAIfkEBQoAAAAsAgAEAAIAAgAABAQQpIQiACH5BAUCAAAALAMAAwACAAMAAAQFEBQAUooAIfkEBQIAAAAsAgAEAA"
              "MAAwAABAYQFAkqSBEAIfkEBQIAAAAsAwAFAAIAAwAABAWwIAASiAAh+QQFAgAAACwEAAMAAQAEAAAEBJAAgCIAIf"
              "kEBQIAAAAsAwAEAAQABAAABAdQDAmqrchGACH5BAUCAAAALAIABQADAAEAAAQDUMgIACH5BAUCAAAALAMABgACAA"
              "IAAAQEEJQCIgA7",
      # 21686 thermometer, cold
      "21686": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAADD/wDM/wzd/y/V/0/e/3Hn/////wAAAAAAAAAAAA"
               "AAAAAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQZEKAJakUHXY2MtlLBUQjxXUM6IkJ7SpQVAQAh+QQFCgAAAC"
               "wCAAEAAQABAAAEAjBEACH5BAUKAAAALAIAAgABAAEAAAQCMEQAIfkEBQoAAAAsAgADAAEAAQAABAIwRAAh+QQFMg"
               "AAACwCAAQAAQABAAAEAjBEADs=",
      # 21685 thermometer, warm
      "21685": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAANoAAOIIAOoTAPMaAPMeAP8vAP/+/v///wAAAAAAAA"
               "AAAAAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQXEAAk67wgpUstpdr2eUMJJoigdhLiWhEAIfkEBQoAAAAsAg"
               "AEAAEAAQAABAKQRAAh+QQFCgAAACwCAAMAAQABAAAEAtBEACH5BAUKAAAALAIAAgABAAEAAAQC8EQAIfkEBTIAAA"
               "AsAAAAAAUACAAABBEQgCRnoRanKzdNQphg0zQCEQA7",
      # 1167 dropfall
      "1167": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAAx6tAyGxBSCxBSm9Ey+/JzW9Kze/Lzi/Pz+/AAAAA"
              "AAAAAAAAAAAAAAACH5BAUKAAAALAIAAAADAAEAAAQEUJQSAQAh+QQFCgAAACwBAAAABQACAAAEB1AUkwyQBUQAIf"
              "kEBQoAAAAsAQAAAAUAAwAABAkQgKSSKBNfHAEAIfkEBQoAAAAsAwABAAMAAQAABATQABMBACH5BAUKAAAALAEAAA"
              "AFAAQAAAQMEAAjZVJJFJOoLkAEACH5BAUKAAAALAEAAAAFAAUAAAQOMBSTgpgq3ZQvNVZRBBEAIfkEBQoAAAAsAQ"
              "AAAAUABgAABBAQSAOCTFZqkFQShZFQYAFEACH5BAUKAAAALAEAAAAFAAcAAAQREAQJKjDUJMtBUolQaJhYABEAIf"
              "kEBQoAAAAsAQABAAUABwAABBQwBCNDMdSaE8RVx1AgoGcklFcEEQAh+QQFCgAAACwBAAAABQAIAAAEEzDIGQy1sh"
              "isTyCacoCICBaJEQEAIfkEBQoAAAAsAQABAAUABwAABA4QgCBrpbSaKU+2QKIkEQAh+QQFCgAAACwBAAIABQAFAA"
              "AECjDIGQy1shisU4gAIfkEBQoAAAAsAQADAAUABQAABAsQgCBrpbSWCUwKEQAh+QQFCgAAACwCAAQAAwAEAAAEBx"
              "AEAIq8wEQAIfkEBQoAAAAsAgAFAAMAAwAABAUQBECljAAh+QQFCgAAACwDAAYAAQABAAAEAjBEACH5BAUeAAAALA"
              "MABwABAAEAAAQCMEQAOw==",
      # 3363 windsock
      "3363": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAISGhPQCFPz+/AAAAAAAAAAAACH5BAUUAAAALAEAAA"
              "AGAAgAAAMOODTQ+isq0Sqt4FqceQIAIfkEBRQAAAAsBAAAAAEAAwAAAwNIEAkAIfkEBRQAAAAsBQAAAAEAAwAAAw"
              "M4EAkAIfkEBRQAAAAsBgAAAAEAAwAAAwNIEAkAIfkEBRQAAAAsBAAAAAEAAwAAAwMYQAkAIfkEBRQAAAAsBQAAAA"
              "EAAwAAAwMYMAkAOw=="
    }
    # Open-Meteo, no key needed: the current weather and the day's low and high. Plain HTTP, as the
    # weather is no secret: an encrypted connection needs more memory in one piece than a TC001
    # beside other scripts has.
    var units = {"km/h": "kmh", "m/s": "ms", "mph": "mph", "kn": "kn"}
    self.unit = store.get("wind")
    self.deg = "C"
    var lat = re.search("-?[0-9]+[.,]?[0-9]*", str(store.get("lat")))
    var lon = re.search("-?[0-9]+[.,]?[0-9]*", str(store.get("lon")))
    self.url = nil
    if lat != nil && lon != nil
      self.url = "http://api.open-meteo.com/v1/forecast?latitude=" + string.replace(lat[0], ",", ".") +
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
  # page its first and second half (nil for none), each [full, short, unit]: full and short as cells
  # for big() 16 rows high, the short one for when the full one does not fit, and the unit small
  # beside them; 8 rows high pieces for text() instead, and no unit. The values white, their units
  # grey.
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
    var fg = self.fg
    var G = 0x909090
    var d = self.deg
    var t = str(round(v[0]))
    var h = str(round(v[1]))
    var w = str(round(v[4]))
    var hi = str(round(v[6]))
    var lo = str(round(v[7]))
    var dir = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][(int(v[5]) * 2 + 45) / 90 % 8]
    if self.tall
      # The day's low and then the high, one after the other
      self.slots = [[[self.cells(t + "'" + d), self.cells(t + "'"), nil], nil],
                    [[self.cells(lo + "'" + d), self.cells(lo + "'"), nil], [self.cells(hi + "'" + d), self.cells(hi + "'"), nil]],
                    [[self.cells(h + "%"), nil, nil], nil],
                    [[self.cells(w), nil, self.unit], [self.cells(dir), nil, nil]]]
    else
      self.slots = [[[[[t, fg], ["°" + d, G]], [[t, fg], ["°", G]]], nil],
                    [[[[lo, fg], ["°" + d, G]], [[lo, fg], ["°", G]]], [[[hi, fg], ["°" + d, G]], [[hi, fg], ["°", G]]]],
                    [[[[h, fg], ["%", G]], nil], nil],
                    [[[[w, fg], [self.unit, G]], [[w, fg]]], [[[dir, fg]], nil]]]
    end
  end

  # A string of "0123456789:-'%/NESWCF" as cells for big().
  def cells(s)
    var out = []
    var i = 0
    while i < size(s)
      out.push(string.find("0123456789:-'%/NESWCF", s[i]))
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
    icon(self.gif[k == 0 ? self.sky : (k == 1 ? (two[1] != nil && !second ? "21686" : "21685") : (k == 2 ? "1167" : "3363"))], o, dy + o)
    var into = second ? ph - half : ph
    var off = 0
    var rows = self.tall ? 16 : 8
    if !second && two[1] != nil && half - into < 400
      off = (400 - (half - into)) * (rows + 1) / 400
    elif second && into < 400
      off = into * rows / 400 - rows
    end
    var w = two[second ? 1 : 0]
    var x0 = self.tall ? 16 : 9                   # 8 rows high a dark column after the icon
    # The wind's direction in the middle of what is left beside the 8×8 icon
    if self.tall && k == 3 && second x0 = 12 end
    var aw = width() - x0
    var y = dy + off
    font("small")
    var txt = w[0]
    if self.tall
      # At twice the size, the short one when the full one with its unit does not fit
      var u = w[2]
      var tw = self.big(txt, 0, 0, false) + (u == nil ? 0 : text_ink_width(u) + 2)
      if tw > aw && w[1] != nil
        txt = w[1]
        u = nil
        tw = self.big(txt, 0, 0, false)
      end
      var x = x0 + max(0, (aw - tw) / 2)
      x += self.big(txt, x, y + 3, true) + 2
      if u != nil text(x, y + 13, u, 0x909090) end
    else
      if text_ink_width(txt) > aw && w[1] != nil txt = w[1] end
      text(x0 + max(0, (aw - text_ink_width(txt)) / 2), y + 6, txt)
    end
  end

  # Cells of the small font at twice its size from x, its cap top at y, 2 columns apart: drawn when d
  # is true, the values white and the units, ° % C F, grey; only measured otherwise. Answers the width.
  def big(cells, x, y, d)
    var w = 0
    var n = size(cells)
    var i = 0
    while i < n
      var ci = cells[i]
      var g = self.font[ci]
      var gw = g & 7
      if d
        var c = ci == 12 || ci == 13 || ci > 18 ? 0x909090 : self.fg
        var r = 0
        while r < 5
          var bits = (g >> (3 + 5 * r)) & 31
          var b = 0
          while bits != 0 && b < gw
            if bits & (1 << (gw - 1 - b)) rect_fill(x + w + b * 2, y + r * 2, 2, 2, c) end
            b += 1
          end
          r += 1
        end
      end
      w += gw * 2 + (i + 1 < n ? 2 : 0)
      i += 1
    end
    return w
  end
end
return Weather()
