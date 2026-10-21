# @name Weather
# @desc The sky and temperature, the day's low and high, humidity and wind from Open-Meteo, as LaMetric's Weather
# @author Oliver Rummeyer
# @version 2.0
# @config lat text "Latitude" default="52.52"
# @config lon text "Longitude" default="13.40"
# @config page number "Each page" default=5 min=2 max=30 unit=s
# @config wind select "Wind in" default=km/h options=km/h,m/s,mph,kn
# @config every number "Update every" default=15 min=5 max=60 unit=min
# @config overlay bool "Rain and snow" default=false
# @config quiet bool "Quiet hours" default=false group="Quiet hours"
# @config qfrom number "From" default=23 min=0 max=23 unit=h group="Quiet hours"
# @config qto number "To" default=8 min=0 max=23 unit=h group="Quiet hours"
import string
class Weather
var fg, tall, font, gif, unit, deg, url, wx, wat, fx, sky, slots, t0, ticks, busy
def init()
self.fg = settings.get("textColor")
if self.fg == nil self.fg = 0xFFFFFF end
self.tall = height() > 8
self.font = [60073275, 59262483, 59826491, 59040059, 8709419, 59040827, 60089403, 8659259, 60089659,
59041083, 262401, 57347, 794, 43008299, 34619659, 77950284, 59827259, 59040827, 89534861,
18122003, 34661435]
self.gif = {
"2282": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAExGBKSeBMzCBPz2BPz2lPz61CH5BAUCAAAALAAAAAAIAAgAAAMaCCBEoqCV0haZ5biLp5zHNDCh90gaATGOkgAAIfkEBQoAAAAsAgABAAQABgAAAwkIB8ylbL0HwUsAIfkEBQoAAAAsAQADAAYAAwAAAwh4UABaqskFEgAh+QQFCgAAACwBAAEABgAGAAADCwhQqtcLvBjnhDcBACH5BAUKAAAALAEAAQAFAAYAAAMLCHAKtfA19SQDhiUAIfkEBQoAAAAsAQADAAQABAAAAwhYsMfQC5SSAAAh+QQFCgAAACwBAAEABgAGAAADCwhQ2v7rLCDZVFIlADs=",
"2285": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAAQCFAQCHAQCLAQCNAQCRAQCVAQCZCwuLGxubLS2tPz+/AAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQYUMhJ6xrjYky670UohkZplkeqpgiytHAEACH5BAUKAAAALAAAAAAIAAgAAAQPEMiZQJ1SZcy7pZ8namEEACH5BAUKAAAALAAAAAAIAAgAAAQPEMipQJ0yZcy7pZ8namEEACH5BAUKAAAALAAAAAAIAAgAAAQQEMi5QJ1SyIG7txT4jYh0RQAh+QQFCgAAACwAAAAACAAIAAAEEBDIyUCdMmVMsJeXJX7kNkYAIfkEBQoAAAAsAAAAAAgACAAABBIQyLlAnVJlPLCXlyV+kvFpYwQAIfkEBQoAAAAsAAAAAAgACAAABBMQyJlAnZJlTLCXlyV+0jEZ2xgBADs=",
"2286": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAERCRFRWBGxSBGxubKSipMS+BMTGxOTm5Pz6BAAAAAAAAAAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQeEIBxzpCgKiXE7FySdAgilKWhrqpQvLDXzZ5EWVIEACH5BAUKAAAALAAAAQAIAAYAAAQTEEh5gABVqJvORRc1jUM4FdhoRQAh+QQFCgAAACwBAAEABgAGAAAEEBBIeYACQmUBEL8TcHBhNUUAIfkEBQoAAAAsAgABAAYABgAABBAQSBmAAuIIJQDq12R1YihFACH5BAUKAAAALAMAAgAFAAUAAAQNECggghIAiQn67R4YAQAh+QQFCgAAACwEAAIABAAFAAAECxAoIJQAaAJ599kRACH5BAUKAAAALAUAAgACAAUAAAQHEBwlFKAyAgAh+QQFCgAAACwGAAIAAgAFAAAECBAMJRQ4ApAIACH5BAUKAAAALAcAAwABAAQAAAQE8JwRIgAh+QQFCgAAACwAAAIAAQAEAAAEBFAgIyIAIfkEBQoAAAAsAAABAAIABgAABAhQgCQRMEXICAAh+QQFCgAAACwBAAEAAgAGAAAECFCAJBEwRcgIACH5BAUKAAAALAAAAQAEAAYAAAQNMAAxQaIAoAxMLhgVAQAh+QQFCgAAACwAAAEABQAGAAAEDxAEIGRNogKA9jZeoVFABAAh+QQFCgAAACwAAAEABgAGAAAEETCcIwSlKQm0kTdgWIxjZVoRACH5BAUKAAAALAEAAQAGAAYAAAQSEAAFRFU2CWQlkqABAkUnCUEEADs=",
"12195": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAERGRISGhMzOzPz+/AAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAMVCFqq842BUmCUbdK46MDAIwyNOA4JACH5BAUKAAAALAYAAQABAAEAAAMCSAkAIfkEBQoAAAAsBgABAAEAAQAAAwJYCQAh+QQFCgAAACwGAAEAAQABAAADAkgJACH5BAUKAAAALAYAAQABAAEAAAMCWAkAIfkEBQoAAAAsBgABAAEAAQAAAwJICQA7",
"2283": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAERCRGxubKSipMTGxOTm5AAAACH5BAUKAAAALAAAAQAIAAYAAAMTCKoi7MKYVoqoleitxfgg1IxAAgAh+QQFCgAAACwAAAEACAAGAAADEQiqAQJNhGcmKI+tbfeAm5MAACH5BAUKAAAALAEAAQAGAAYAAAMNCKoBLQEKUGZbbuKrEgAh+QQFCgAAACwCAAEABgAGAAADDQiqAS0BClBmW27iqxIAIfkEBQoAAAAsAwACAAUABQAAAwsIARIhoDRAFayLJgAh+QQFCgAAACwEAAIABAAFAAADCQgBEgJlAfWmTAAh+QQFCgAAACwFAAIAAgAFAAADBggREioqAQAh+QQFCgAAACwGAAIAAgAFAAADBggREioqAQAh+QQFCgAAACwHAAMAAQADAAADAhiaACH5BAUKAAAALAAAAgABAAQAAAMDKEWSACH5BAUKAAAALAAAAQACAAYAAAMHKGBaQEOoBAAh+QQFCgAAACwBAAEAAgAGAAADByhgWkBDqAQAIfkEBQoAAAAsAAABAAQABgAAAwsYIAvGAJQISByQJQAh+QQFCgAAACwAAAEABQAGAAADDQgBom2iAVDmJHZIBhIAIfkEBQoAAAAsAAABAAYABgAAAw8IECAdzojiVFGYYDCqcgkAIfkEBQoAAAAsAQABAAYABgAAAw8IECAdzojiVFGYYDCqcgkAOw==",
"17056": "data:image/gif;base64,R0lGODlhCAAIAIEAAAAAAAAAAMzOzAAAACH5BAUyAAAALAAAAQAIAAUAAAIJhH6gy2jOIkoFACH5BAUyAAAALAEAAQAGAAUAAAIIDA6Cm8anUCgAOw==",
"2284": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAACRCzERCRERSjGxubKSipMTGxOTm5AAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAUUAAAALAAAAAAIAAgAAAQbEEg5BrUDoXrO6J0hjuJQnKglVKswvTAByEAEACH5BAUUAAAALAEABQAGAAMAAAQJkIwhiQjhXswjACH5BAUUAAAALAEABQAGAAMAAAQKcAAxKAHgEoG5iAAh+QQFFAAAACwBAAUABgADAAAEChAAMkEAImRaSQQAIfkEBRQAAAAsAQAFAAYAAwAABAlwyBkCsTUIHSIAOw==",
"2289": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAERCRGxubKSipMTGxOTm5AAAACH5BAUKAAAALAAAAAAIAAgAAAMXCKoi7MKYVoqoleitxfgg1IxLuRgKqiQAIfkEBQoAAAAsAQAFAAYAAwAAAwdoImrxML4EACH5BAUKAAAALAEABQAGAAIAAAMGKAAqts8kACH5BAUKAAAALAEABQAGAAMAAAMIaLAa60EBZRIAIfkEBQoAAAAsAQAFAAYAAwAAAwcouhbeLoYEACH5BAUKAAAALAEABQAGAAMAAAMICGBqoeCxBhIAIfkEBQoAAAAsAQAFAAYAAwAAAwcouhHWr8kEACH5BAUKAAAALAEABQAGAAMAAAMIaAC6EAuyZRIAIfkEBQoAAAAsAQAFAAYAAwAAAwcouhbRLroEADs=",
"2288": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAADQyNERCRGxqbIRyRKyurMTGxNSqLPzSBAAAAAAAAAAAAAAAAAAAAAAAACH5BAUyAAAALAAAAAAIAAYAAAQWEEgpBLXinGqM6B0hjmI1COcJVKwVAQAh+QQFAgAAACwEAAMAAQABAAAEArBEACH5BAUCAAAALAMAAwAEAAIAAAQHECAAihgiAgAh+QQFAgAAACwCAAMAAwADAAAEBxCABBAoMgIAIfkEBQoAAAAsAgAEAAIAAgAABAQQpIQiACH5BAUCAAAALAMAAwACAAMAAAQFEBQAUooAIfkEBQIAAAAsAgAEAAMAAwAABAYQFAkqSBEAIfkEBQIAAAAsAwAFAAIAAwAABAWwIAASiAAh+QQFAgAAACwEAAMAAQAEAAAEBJAAgCIAIfkEBQIAAAAsAwAEAAQABAAABAdQDAmqrchGACH5BAUCAAAALAIABQADAAEAAAQDUMgIACH5BAUCAAAALAMABgACAAIAAAQEEJQCIgA7",
"21686": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAADD/wDM/wzd/y/V/0/e/3Hn/////wAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQZEKAJakUHXY2MtlLBUQjxXUM6IkJ7SpQVAQAh+QQFCgAAACwCAAEAAQABAAAEAjBEACH5BAUKAAAALAIAAgABAAEAAAQCMEQAIfkEBQoAAAAsAgADAAEAAQAABAIwRAAh+QQFMgAAACwCAAQAAQABAAAEAjBEADs=",
"21685": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAANoAAOIIAOoTAPMaAPMeAP8vAP/+/v///wAAAAAAAAAAAAAAAAAAAAAAACH5BAUKAAAALAAAAAAIAAgAAAQXEAAk67wgpUstpdr2eUMJJoigdhLiWhEAIfkEBQoAAAAsAgAEAAEAAQAABAKQRAAh+QQFCgAAACwCAAMAAQABAAAEAtBEACH5BAUKAAAALAIAAgABAAEAAAQC8EQAIfkEBTIAAAAsAAAAAAUACAAABBEQgCRnoRanKzdNQphg0zQCEQA7",
"1167": "data:image/gif;base64,R0lGODlhCAAIAIMAAAAAAAAAAAx6tAyGxBSCxBSm9Ey+/JzW9Kze/Lzi/Pz+/AAAAAAAAAAAAAAAAAAAACH5BAUKAAAALAIAAAADAAEAAAQEUJQSAQAh+QQFCgAAACwBAAAABQACAAAEB1AUkwyQBUQAIfkEBQoAAAAsAQAAAAUAAwAABAkQgKSSKBNfHAEAIfkEBQoAAAAsAwABAAMAAQAABATQABMBACH5BAUKAAAALAEAAAAFAAQAAAQMEAAjZVJJFJOoLkAEACH5BAUKAAAALAEAAAAFAAUAAAQOMBSTgpgq3ZQvNVZRBBEAIfkEBQoAAAAsAQAAAAUABgAABBAQSAOCTFZqkFQShZFQYAFEACH5BAUKAAAALAEAAAAFAAcAAAQREAQJKjDUJMtBUolQaJhYABEAIfkEBQoAAAAsAQABAAUABwAABBQwBCNDMdSaE8RVx1AgoGcklFcEEQAh+QQFCgAAACwBAAAABQAIAAAEEzDIGQy1shisTyCacoCICBaJEQEAIfkEBQoAAAAsAQABAAUABwAABA4QgCBrpbSaKU+2QKIkEQAh+QQFCgAAACwBAAIABQAFAAAECjDIGQy1shisU4gAIfkEBQoAAAAsAQADAAUABQAABAsQgCBrpbSWCUwKEQAh+QQFCgAAACwCAAQAAwAEAAAEBxAEAIq8wEQAIfkEBQoAAAAsAgAFAAMAAwAABAUQBECljAAh+QQFCgAAACwDAAYAAQABAAAEAjBEACH5BAUeAAAALAMABwABAAEAAAQCMEQAOw==",
"3363": "data:image/gif;base64,R0lGODlhCAAIAIIAAAAAAAAAAISGhPQCFPz+/AAAAAAAAAAAACH5BAUUAAAALAEAAAAGAAgAAAMOODTQ+isq0Sqt4FqceQIAIfkEBRQAAAAsBAAAAAEAAwAAAwNIEAkAIfkEBRQAAAAsBQAAAAEAAwAAAwM4EAkAIfkEBRQAAAAsBgAAAAEAAwAAAwNIEAkAIfkEBRQAAAAsBAAAAAEAAwAAAwMYQAkAIfkEBRQAAAAsBQAAAAEAAwAAAwMYMAkAOw=="
}
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
def loop()
if self.url == nil || self.busy return end
self.ticks -= 1
if self.ticks > 0 return end
self.ticks = int(store.get("every")) * 60
self.busy = true
http.get(self.url, / b, s -> self.on_weather(b, s), {'find': '"current":{', 'keep': 400})
end
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
def build()
var v = self.wx
var day = v[2] > 0
var code = int(v[3])
self.fx = nil
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
if self.tall
self.slots = [[[tc, self.cells(t + "'" + d), self.cells(t + "'"), nil], nil],
[[B, self.cells(lo + "'" + d), self.cells(lo + "'"), nil], [R, self.cells(hi + "'" + d), self.cells(hi + "'"), nil]],
[[fg, self.cells(h + "%"), nil, nil], nil],
[[fg, self.cells(w), nil, self.unit], [fg, self.cells(dir), nil, nil]]]
else
self.slots = [[[tc, t + "°" + d, t + "°"], nil],
[[fg, [[lo, B], ["/", fg], [hi + "°" + d, R]], [[lo, B], ["/", fg], [hi, R]]], nil],
[[fg, h + "%", nil], nil],
[[fg, w + self.unit, w], [fg, dir, nil]]]
end
end
def cells(s)
var out = []
var i = 0
while i < size(s)
out.push(string.find("0123456789:-'%/NESWCF", s[i]))
i += 1
end
return out
end
def quiet()
if !store.get("quiet") || epoch_ms() < 0 return false end
var h = hour()
var f = int(store.get("qfrom"))
var t = int(store.get("qto"))
return f > t ? (h >= f || h < t) : (h >= f && h < t)
end
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
def show(k, dy, ph, ms)
var two = self.slots[k]
var half = (ms + 300) / 2
var second = two[1] != nil && ph >= half
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
var x0 = self.tall ? 18 : 9
if self.tall && k == 3 && second x0 = 12 end
var aw = width() - x0
var y = dy + off
font("small")
var txt = w[1]
if self.tall
var u = w[3]
var tw = self.big(txt, 0, 0, nil) + (u == nil ? 0 : text_ink_width(u) + 2)
if tw > aw && w[2] != nil
txt = w[2]
u = nil
tw = self.big(txt, 0, 0, nil)
end
var x = x0 + max(0, (aw - tw) / 2)
x += self.big(txt, x, y + 3, w[0]) + 2
if u != nil text(x, y + 13, u, 0x909090) end
else
if text_ink_width(txt) > aw && w[2] != nil txt = w[2] end
text(x0 + max(0, (aw - text_ink_width(txt)) / 2), y + 6, txt, w[0])
end
end
def big(cells, x, y, c)
var w = 0
var n = size(cells)
var i = 0
while i < n
var g = self.font[cells[i]]
var gw = g & 7
if c != nil
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
