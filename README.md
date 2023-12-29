# KuruKuruKurandomizer
A randomizer for Kuru Kuru Kururin.

## Requirements
- [Bizhawk Emulator](https://tasvideos.org/Bizhawk)
- A European ROM of Kuru Kuru Kururin. Probably called `Kurukuru Kururin (Europe).gba`
- The latest release form the [releases](https://github.com/GirambQuamb/KuruKuruKurandomizer/releases) page

## Setup
1. Download the latest `.zip` file from the [releases](https://github.com/GirambQuamb/KuruKuruKurandomizer/releases) page and extract into an empty folder
2. Patch your ROM file, `Kurukuru Kururin (Europe).gba` with the included .xdelta file, using [Rom Patcher JS](https://www.romhacking.net/patch/) or [xdelta UI](https://www.romhacking.net/utilities/598/)
3. Ensure the patched ROM is inside the folder with all the .lua scripts
4. (Optional) Modify the randomizer settings by editing `settings.lua` in any text editor

## Playing
1. Launch the patched ROM through Bizhawk
2. Once the game has started, simply drag `kurandomizer.lua` on top of the emulator window, or select it through the `Lua Console` under `Tools`
