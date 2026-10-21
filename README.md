# awtrix-ng-lametric-apps

Two apps for an [AWTRIX NG](https://github.com/Blueforcer/awtrix-ng) Ulanzi
TC002 or TC001, in place of the LaMetric Time's
[Alarm Clock](https://apps.lametric.com/apps/alarm_clock), without the alarm,
and [Weather](https://apps.lametric.com/apps/weather).

**Clock** ([`Clock.be`](Clock.be)): the time beside LaMetric's flame, 7756,
the days of the week under it, laid out as the clock's own Time app. On the
TC002 the flame takes the place of the Time app's calendar sheet, and the
time the same double-size digits beside it:

```
 ┌────────┐ ██ ██   ██ ██
 │ flame  │  █ ██ ▪  █  █
 │ 16×16  │  █  █ ▪  █  █
 └────────┘ ▬▬ ▬▬ ██ ▬▬ ▬▬ ▬▬ ▬▬
```

On the TC001 the time is in the small font beside it. With the icon
switched off it shows the time with seconds across the whole display.

**Weather** ([`Weather.be`](Weather.be)): four pages, each one of LaMetric's
icons and its value, as on the LaMetric:

| Icon | Shows |
|---|---|
| The sky: sunny 2282, night 2285, partly cloudy 2286 and at night 12195, cloudy 2283, fog 17056, rainy 2284, snowy 2289, stormy 2288 | the temperature, `14°C` |
| A thermometer, cold 21686 with the low, warm 21685 with the high | the day's low and high: on the TC002 at twice the size, the low and halfway the high; on the TC001 in one line, `9/14°C` |
| A falling drop, 1167 | the humidity |
| A windsock, 3363 | the wind speed, halfway giving way to where it comes from, N, NE, E … |

The icons come with the scripts, made as small as GIFs go while they play
the same, about 7 KB for all of them; nothing is fetched from LaMetric or
installed. On the TC002 they stand in the middle of the 16×16 square and the
values are twice the size of the small font where they fit; on the TC001 the
small font. Halfway through a page with two values the first slides out at
the bottom and the second in from the top.

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

**On a TC001** install [`Clock.tc001.be`](Clock.tc001.be) and
[`Weather.tc001.be`](Weather.tc001.be) instead. A TC001 shares 96 KB among its
scripts, and a script compiles only into memory in one piece as large as its
source, so these copies leave out the comments, the indentation and the
settings' help texts. [`tc001.py`](tc001.py) makes them from the scripts:
run `python3 tc001.py` after changing one.

They still cost about 13 KB (Clock) and 20 KB (Weather). Beside the Netatmo
app, which takes 29 KB and needs a large piece of memory for its encrypted
connection, there is room for the Clock but not the Weather: with both,
Netatmo cannot reach its server any more. If saving a script makes the
clock restart and keep the old version, delete the app, restart the clock
and install it again.

## Settings

On the **Apps** tab, the gear button on the app's row.

**Clock**

| Setting | Default | |
|---|---|---|
| Icon | on | LaMetric's flame beside the time. Off shows the time with seconds. |
| Weekday | on | The days of the week under the time. |
| Week starts Monday | on | Off starts it on Sunday. |
| Today / Other days | white / grey | The colours of the weekday bars, those of the Time app. |
| Quiet hours | off, 23 to 8 h | Only HH:MM in the middle of the display, nothing else, across midnight too. |
| Brightness | 1 % | Of the display while the Clock is shown in the quiet hours. The old brightness comes back as soon as the next app comes, also after a restart in between. |

24 or 12 hours, the leading zero, the colon (steady, blinking or pulsing) and
the time's colour are the clock's own time settings. The Clock stays as long
as any app.

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

MIT. The icons are from the [LaMetric icon gallery](https://developer.lametric.com/icons)
and belong to their authors; the double-size digits are the clock's small font
(SIL OFL 1.1, see the AWTRIX NG font notices); the weather is by
[Open-Meteo](https://open-meteo.com) (CC BY 4.0).
