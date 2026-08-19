## Home Assistant — DEEBOT X2 OMNI temporary patch

This fork contains additional support for the ECOVACS DEEBOT X2 OMNI
(`lf3bn4`), developed on the `x2-omni-station-support` branch.

The changes add support for:

- Auto-empty frequency
- Empty dustbin
- Dry mop
- Clean base
- Station state
- Washing mop station state handling

The changes have been tested with a physical DEEBOT X2 OMNI using
Home Assistant and `deebot-client` 18.5.1.

### Why the patch is needed

Home Assistant installs its own released version of `deebot-client`.
Until the X2 OMNI changes are merged upstream and included in a released
version of `deebot-client`, a Home Assistant Core update may replace the
patched files with the standard versions.

The script:

    scripts/apply_x2_omni_patch.sh

downloads the patched files from the `x2-omni-station-support` branch and
installs them into the `deebot-client` package currently used by Home
Assistant.

The script dynamically determines the installed Python/site-packages
location, so it is not tied to a specific Python version.

### After a Home Assistant Core update

From the Home Assistant OS host, run:

    sudo docker exec -it homeassistant /config/deebot_patch/apply_x2_omni_patch.sh

If /config/deebot_patch/apply_x2_omni_patch.sh is missing download it from this repository dev branch
  scripts/apply_x2_omni_patch.sh

The script will display the status of:

    e6ofmn.py
    lf3bn4.py
    clean.py
    station_state.py

If all files are already patched, it exits without making changes.

If the Home Assistant update has replaced them, the script:

1. Downloads the current patch files from GitHub.
2. Backs up the installed `deebot-client` files.
3. Applies the X2 OMNI patch.
4. Removes the Python bytecode cache.
5. Verifies the installed files and expected patch markers.

After a successful patch, restart Home Assistant Core:

    sudo docker restart homeassistant

### Patch files

The patch modifies the installed copies of:

    deebot_client/hardware/e6ofmn.py
    deebot_client/hardware/lf3bn4.py
    deebot_client/commands/json/clean.py
    deebot_client/messages/json/station_state.py

`lf3bn4` uses the `e6ofmn` hardware definition, so the patched
`e6ofmn.py` is installed for both hardware identifiers.

Backups are stored under:

    /config/deebot_patch/backups/

### Removing the workaround

This workaround should no longer be necessary once the X2 OMNI changes
have been merged into `DeebotUniverse/client.py` and the corresponding
`deebot-client` release is included in Home Assistant.

At that point, stop running the patch script and verify that the released
integration provides the required X2 OMNI station capabilities before
removing `/config/deebot_patch`.
# Client Library for Deebot devices (Vacuums)

[![PyPI - Downloads](https://img.shields.io/pypi/dw/deebot-client?style=for-the-badge)](https://pypi.org/project/deebot-client)
<a href="https://www.buymeacoffee.com/edenhaus" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-black.png" width="150px" height="35px" alt="Buy Me A Coffee" style="height: 35px !important;width: 150px !important;" ></a>

## IMPORTANT: Contribution only

This project is maintained in our spare time. Please be patient and respectful.

It's not related to Ecovacs or Deebot and we don't get any support from them.

As all is reverse engineered it might take some time to add new features and we can't guarantee that all features will be added.

Unfortunately some people think we are paid to do this and get angry if things don't work as they expect.
**As result of this, we decided that this project is in a contribution only mode.**

This means, if you want something to be supported/added, you have to provide a fix yourself, wait for someone else to fix it or pay someone to do it.
Members will still review and help on pull requests.

## Installation

If you have a recent version of Python 3, you should be able to
do `pip install deebot-client` to get the most recently released version of
this.

## Usage

To get started, you'll need to have already set up an EcoVacs account
using your smartphone.

You are welcome to try using this as a python library for other efforts.
A simple usage might go something like this:

```python
import aiohttp
import asyncio
import logging
import time

from deebot_client.api_client import ApiClient
from deebot_client.authentication import Authenticator, create_rest_config
from deebot_client.commands.json.clean import Clean, CleanAction
from deebot_client.events import BatteryEvent
from deebot_client.mqtt_client import MqttClient, create_mqtt_config
from deebot_client.util import md5
from deebot_client.device import Device

device_id = md5(str(time.time()))
account_id = "your email or phonenumber (cn)"
password_hash = md5("yourPassword")
country = "DE"


async def main():
  async with aiohttp.ClientSession() as session:
    logging.basicConfig(level=logging.DEBUG)
    rest_config = create_rest_config(session, device_id=device_id, alpha_2_country=country)

    authenticator = Authenticator(rest_config, account_id, password_hash)
    api_client = ApiClient(authenticator)

    devices_ = await api_client.get_devices()

    bot = Device(devices_.mqtt[0], authenticator)

    mqtt_config = create_mqtt_config(device_id=device_id, country=country)
    mqtt = MqttClient(mqtt_config, authenticator)
    await bot.initialize(mqtt)

    async def on_battery(event: BatteryEvent):
      # Do stuff on battery event
      if event.value == 100:
        # Battery full
        pass

    # Subscribe for events (more events available)
    bot.events.subscribe(BatteryEvent, on_battery)

    # Execute commands
    await bot.execute_command(Clean(CleanAction.START))
    await asyncio.sleep(900)  # Wait for...
    await bot.execute_command(Charge())


if __name__ == '__main__':
  loop = asyncio.get_event_loop()
  loop.create_task(main())
  loop.run_forever()
```

A more advanced example can be found [here](https://github.com/And3rsL/Deebot-for-Home-Assistant).

### Note for Windows users

This library cannot be used out of the box with Windows due a limitation in the requirement `aiomqtt`.
More information and a workaround can be found [here](https://github.com/sbtinstruments/aiomqtt#note-for-windows-users)

## Thanks

My heartfelt thanks to:

- [deebotozmo](https://github.com/And3rsL/Deebotozmo), After all, this is a debotozmo fork :)
- [sucks](https://github.com/wpietri/sucks), deebotozmo was forked from it :)
- [xmpppeek](https://www.beneaththewaves.net/Software/XMPPPeek.html), a great library for examining XMPP traffic flows (
  yes, your vacuum speaks Jabber!),
- [mitmproxy](https://mitmproxy.org/), a fantastic tool for analyzing HTTPS,
- [click](http://click.pocoo.org/), a wonderfully complete and thoughtful library for making Python command-line
  interfaces,
- [requests](http://docs.python-requests.org/en/master/), a polished Python library for HTTP requests,
- [Decompilers online](http://www.javadecompilers.com/apk), which was very helpful in figuring out what the Android app
  was up to,
- Albert Louw, who was kind enough to post code
  from [his own experiments](https://community.smartthings.com/t/ecovacs-deebot-n79/93410/33)
  with his device, and
- All the users who have given useful feedback and contributed code!
