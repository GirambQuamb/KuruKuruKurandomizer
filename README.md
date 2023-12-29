# KuruKuruKurandomizer
A randomizer for Kuru Kuru Kururin utilizing Bizhawk-specific Lua scripts.

## Requirements
- [Bizhawk Emulator](https://tasvideos.org/Bizhawk)
- A European ROM of Kuru Kuru Kururin, probably called `Kurukuru Kururin (Europe).gba`
- The latest release form the [releases](https://github.com/GirambQuamb/KuruKuruKurandomizer/releases) page

## Setup
1. Download the latest `.zip` file from the [releases](https://github.com/GirambQuamb/KuruKuruKurandomizer/releases) page and extract into an empty folder
2. Patch your vanilla ROM file with the included `.bps` file ([Rom Patcher JS](https://www.romhacking.net/patch/) does the trick)
3. Ensure the patched ROM is inside the folder with all the `.lua` scripts
4. (Optional) Modify the randomizer settings by editing `settings.lua` in any text editor

## Starting a Run
To play, simply launch the patched ROM through Bizhawk. Once the game has started, drag `kurandomizer.lua` on top of the emulator window, or select it through the `Lua Console` under `Tools`. The Lua Console must remain open for this randomizer to work, though it can be minimized.

Once you have passed the title screen and made it to the world map, two files should appear in the directory, `random.dat` and `random.json`. These keep track of your progress. If you reboot or close the emulator, simply launch the ROM and run `kurandomizer.lua` again to regain progress. 

Deleting `random.dat` and `random.json` will allow you to start a new game.

## Related Repositories
A massive thanks to the minds behind these repositories, which served as inspiration and guidance

- [KuruTools](https://github.com/E-Sh4rk/KuruTools) - Various useful tools and utilities related to Kuru Kuru Kururin and Kururin Paradise
- [KururinTAS](https://github.com/E-Sh4rk/KururinTAS) - Various TAS-related tools and files related to Kuru Kuru Kururin
- [KHCOM_RANDO](https://github.com/gaithern/KHCOM_RANDO) - A Kingdom Hearts: Chain of Memories randomizer that works similarly through Bizhawk-specific Lua scripts
