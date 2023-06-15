# unitscan-WoTLK-3.3.5
Backport of **unitscan-rares** with extra functionality, that already has all rares listed.

![unitscan](https://user-images.githubusercontent.com/74269253/233365890-eac8b750-d256-4852-abb5-67f0224a7fe1.gif)


## Credit
- Credit to [simon_hirsig](https://legacy.curseforge.com/members/simon_hirsig/projects) & [tablegrapes](https://legacy.curseforge.com/members/tablegrapes/projects)
- Code from [unitscan](https://legacy.curseforge.com/wow/addons/unitscan) & [unitscan-rares](https://www.curseforge.com/wow/addons/unitscan-rares)
- Credit to [Macumbafeh](https://github.com/Macumbafeh/) for checking all rares in list and then adding frFR database!


## Download & Installation

1. [Download](https://github.com/Sattva-108/unitscan-WoTLK-3.3.5/archive/refs/heads/main.zip) zip.
2. Copy the `unitscan` folder within the "unitscan-WoTLK-3.3.5-main" folder inside the .zip into the game folder `"\Interface\AddOns\"`.    
3. Replace/overwrite any existing files when copying.


## Usage
1. **`/unitscan`**
 - general chat command to list all your custom units and shows available commands.
 
2. **`/unitscan target`**
 - will add/remove your current target from the list of scanned units.
 
3. **`/unitscan 'name of unit to scan'`**
 - adds/removes the 'unit' from the unit scanner
 
4. **`/unistcan nearby`**
- will print all rares that you can find in current zone.

5. **`/unitscan ignore 'name of rare here'`**
- allows you to add/remove certain rare mob from scan list. 

5. **`Left-Click`** on button to choose target.
6. **`Ctrl-Click`** will move the frame to your desired position.
7. **`Right-click`** will close the frame.

## What's new with backport?
1. You are now able to add your current target to the list via slash command. 
You could also make a macro
```lua 
/unitscan target
```

2. Can now close button on right click.
You could also make a macro to close a button

```lua 
/click unitscan_close
```

3. Added ruRU - Russian database of rare mobs by @Sattva-108
4. Added frFR - French database of rare mobs by @Macumbafeh
5. Added zhCN - Chinese database by anonymous contributor.
6. Added new slash command that allow you to add/remove certain rare mob from scan list. 
```lua
/unitscan ignore 'name of rare here'
```
7. And more features, can't list all!

#### `Changelog`, `To Do List` and `known bugs` can be viewed in [Changelog and Notes.txt](https://github.com/Sattva-108/unitscan-WoTLK-3.3.5/blob/main/unitscan/Changelog%20and%20Notes.txt) inside addon folder.
