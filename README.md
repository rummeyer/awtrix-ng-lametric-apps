# awtrix-ng-lametric-apps

Two apps for an [AWTRIX NG](https://github.com/Blueforcer/awtrix-ng) Ulanzi
TC002 or TC001, in place of the LaMetric Time's
[Alarm Clock](https://apps.lametric.com/apps/alarm_clock), without the alarm,
and [Weather](https://apps.lametric.com/apps/weather).

**Clock** ([`Clock.be`](Clock.be)): the time beside an icon, the days of the
week under it, laid out as the clock's own Time app. On the TC002 the icon
takes the place of the Time app's calendar sheet, and the time the same
double-size digits beside it:

```
 ┌────────┐ ██ ██   ██ ██
 │  icon  │  █ ██ ▪  █  █
 │ 16×16  │  █  █ ▪  █  █
 └────────┘ ▬▬ ▬▬ ██ ▬▬ ▬▬ ▬▬ ▬▬
```

On the TC001 the icon is 8×8 and the time in the small font beside it.
Without an icon it shows the time with seconds across the whole display.

**Weather** ([`Weather.be`](Weather.be)): four pages, each one of LaMetric's
icons and its value, as on the LaMetric:

| Icon | Shows |
|---|---|
| The sky: sunny 2282, night 2285, partly cloudy 2286 and at night 12195, cloudy 2283, fog 17056, rainy 2284, snowy 2289, stormy 2288 | the temperature, `14°C` |
| A thermometer, cold 21686 with the low, warm 21685 with the high | the day's low and high: on the TC002 at twice the size, the low and halfway the high; on the TC001 in one line, `9/14°C` |
| A falling drop, 1167 | the humidity |
| A windsock, 3363 | the wind speed, halfway giving way to where it comes from, N, NE, E … |

The icons have to be on the clock, on the TC002 too, so that still and
animated ones keep the same 8×8: [`install-icons.py`](install-icons.py) puts
them there (see Installing). On the TC002 they stand in the middle of the
16×16 square and the values are twice the size of the small font where they
fit; on the TC001 the small font. Halfway through a page with two values the
first slides out at the bottom and the second in from the top.

The weather comes from [Open-Meteo](https://open-meteo.com), which needs no
key or account. The pages slide down one after the other.

## Installing

In the clock's web UI, opened by its IP address or local name, go to
**Scripts**, create a script named `Clock`, paste in [`Clock.be`](Clock.be)
and save; the same for `Weather` with [`Weather.be`](Weather.be). Or from a
computer on the same network:

```sh
curl -X PUT "http://<awtrix-ip>/api/v1/apps/script/Clock" \
  -H "Content-Type: text/plain" --data-binary @Clock.be
curl -X PUT "http://<awtrix-ip>/api/v1/apps/script/Weather" \
  -H "Content-Type: text/plain" --data-binary @Weather.be
```

You will want to switch off the clock's own **Time** app, and on the TC001
**Temperature** and **Humidity** too, so the rotation does not show them
twice.

**The icons.** The Weather's icons have to be on the clock, and on a TC001,
which cannot draw pictures from a web address, the Clock's too.
[`install-icons.py`](install-icons.py) puts them there: it reads the Clock's
icon from its settings, takes the Weather's icons when that app is
installed, and installs every one the clock does not have yet, a still PNG
turned into a GIF. It needs Python 3 and nothing else and leaves installed
icons alone, so it can run after every change of the icon:

```sh
python3 install-icons.py <awtrix-ip>
```

Until then the TC001 shows a little clock face in the Clock's icon's place,
and the Weather leaves the icons out.

## Settings

On the **Apps** tab, the gear button on the app's row.

**Clock**

| Setting | Default | |
|---|---|---|
| Icon | `7756` | A number from the [LaMetric icon gallery](https://developer.lametric.com/icons), or an icon's name on the clock. Empty shows the time with seconds. |
| Weekday | on | The days of the week under the time. |
| Week starts Monday | on | Off starts it on Sunday. |
| Today / Other days | white / grey | The colours of the weekday bars, those of the Time app. |
| Quiet hours | off, 23 to 8 h | Only HH:MM in the middle of the display, nothing else, across midnight too. |
| Brightness | 1 % | Of the display while the Clock is shown in the quiet hours. The old brightness comes back as soon as the next app comes, also after a restart in between. |

24 or 12 hours, the leading zero, the colon (steady, blinking or pulsing) and
the time's colour are the clock's own time settings. The Clock stays as long
as any app.

**Icons** are numbers from the [LaMetric icon gallery](https://developer.lametric.com/icons):
the TC002 draws them from
`https://developer.lametric.com/content/apps/icon_thumbs/<number>`, a still
one filling the 16×16 square, an animated one at its own 8×8 in the middle
of it,. On a TC001 the number names an icon installed on the clock, shown at
8×8 (see Installing). Any other name is an icon on the clock, such as one
installed from the [AWTRIX Hub](https://awtrix.de/icons). An icon that
cannot be found gets a clock face.

**Weather**

| Setting | Default | |
|---|---|---|
| Latitude / Longitude | 52.52 / 13.40 | Where the weather is for, Berlin until set. |
| Each page | 5 s | How long each of the four pages stays. |
| Wind in | km/h | km/h, m/s, mph or kn. |
| Update every | 15 min | |
| Rain and snow | off | The clock's rain, drizzle, snow and thunder overlay over the pages. |
| Quiet hours | off, 23 to 8 h | Left out of the rotation between these hours, across midnight too. The weather keeps coming, so it is up to date in the morning. |

Temperatures follow the clock's °C/°F setting, and the current one the
clock's temperature colour where set. On the TC002 values are drawn at
twice the size where they fit, else in the small font. The last weather is
kept over a restart; weather more than three hours old is left out of the
rotation until a new one comes.

## Licence

MIT. The default icon is from the [LaMetric icon gallery](https://developer.lametric.com/icons)
and belongs to its author; the double-size digits are the clock's small font
(SIL OFL 1.1, see the AWTRIX NG font notices); the weather is by
[Open-Meteo](https://open-meteo.com) (CC BY 4.0).
