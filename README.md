## Notice of Non-Affiliation and Disclaimer

This project is not affiliated with, associated with, authorized by, endorsed by, or in any way officially connected to [**Discord™**](https://discordapp.com), [**Portapps**](https://portapps.io/app/discord-portable), or [**BetterDiscord**](https://betterdiscord.app), or any of their subsidiaries or affiliates.

The names **Discord™**, **Portapps**, and **BetterDiscord**, as well as related names, marks, emblems and images, are registered trademarks of their respective owners.

<br>

## FEATURES

- **BetterDiscord**

  This Discord client comes with BetterDiscord preinstalled, an enhanced version that expands Discord’s functionality by allowing you to install plugins and themes, apply custom CSS, and access additional settings.

- **Portability**

  All program data is stored in the same folder, with no shortcuts and no files in `%AppData%` or the registry. Which makes it a fully portable version that you can easily move between devices or run directly from a USB drive.

- **Multi-instancing**

  This feature allows you to open multiple independent instances of the program at the same time, making it easy to manage different accounts, use separate settings profiles, or join multiple calls simultaneously.

<br>

## FAQ

- **How does it work?**

  This project mimics Portapps approach while keeping updates working. The Electron userData path is forced to the data folder inside the portable root. Additionally, the injection is repatched on launch if it gets removed after an automatic update.

- **Why don't you use the Discord portable made by Portapps?**

  Discord portable and BetterDiscord are incompatible with each other. Installing BetterDiscord on the Portapps build is technically possible, but causes Discord to break after the first launch. Full explanation below.

- **For all BetterDiscord-related questions (PTB / Canary compatibility, ban risk, etc.), please refer to the BetterDiscord project page.**

<br>

## Technical Background (Summary)

### Archieving portability

- **Understanding the problem:**

  In the Discord installation root, under `<discord-root>/app-<version>/resources`, there is a file called `app.asar` that contains much of Discord's runtime code.

  In the Portapps version of Discord, however, the app content is an unwrapped folder (named `app/`) instead of an .asar archive.  
  This happens because Portapps makes Discord portable by decompiling the `app.asar` file and modifying the default data path variables.

  When BetterDiscord is installed on a Portapps portable build and the app runs, something in the shutdown/cleanup process causes the `app/` folder to be removed.  
  BetterDiscord itself does not directly delete these files, but its presence changes the behavior of the Portapps client in a way that indirectly triggers this removal.

  BetterDiscord modifies a single file in the base Discord installation:

  `<discord-root>\app-<version>\modules\discord_desktop_core-1\discord_desktop_core\index.js`

  It does it by adding a single line that references an additional file called `betterdiscord.asar` located within BetterDiscord's data folder which contains its libraries and code.

- **My approaches and solution:**

  First attempt (restoring the removed files at launch).
  I stored a copy of the `app/` folder in the portable root and made the launcher copy it back into place before launching Discord. This worked but felt hacky, prevented easy updates, and introduced downsides when trying to move to newer Discord versions.

  Second attempt (use normal installer files)
  I tried updating the old version app files to a newer release, which came with the `app.asar` file so Discord would not self-destruct after BetterDiscord installation. That fixed the issue but made Discord stop using the portable root `data/` folder and instead wrote to `%APPDATA%` (like a normal install) since the patch got removed in the update. This meant it was no longer truly portable.

  Final approach (portable launcher using environment variable)
  I created a small launcher script (a .bat file) that sets the Electron userData path environment variable to the portable root `data/` directory before launching Discord, without modifying the code. This made Discord (and BetterDiscord) use the portable `data/` folder. I also relocated the `betterdiscord.asar` file to the root so it would not be stored inside the `data/` folder (this folder is generated at runtime and should not be uploaded to the repo).

  With this method I achieved a fully portable and updatable Discord that supports BetterDiscord.

<br>

### Archieving multi-instancing

- **Understanding the problem:**

  Typically, multi-instancing works by running the program multiple times, each instance using a different data folder. This creates parallel processes that do not interfere with each other.

  The challenge is determining which data folder to assign to a new instance. To do this, we first need to know how many instances are already running. Windows provides tools for this, and in this case, we can use `wmic` to count the number of processes for a specific program.

  The complication is that `wmic` counts the total number of processes for a given application. Each Discord instance usually has 6 subprocesses, but sometimes can go up to 7. Because of this, simply dividing the total process count by 6 is unreliable. While a formula could approximate the number of instances, it would become increasingly inaccurate as more instances are running.

- **My approaches and solution:**

  To begin with, I slightly modified the previous portable approach by configuring the `data/` directory to store separate `profile-<profile-index>` folders, rather than storing data directly. Each folder represents a distinct Discord instance, and is automatically generated at runtime.

  First approach: I initially attempted to enumerate all active Discord processes using `wmic`. This method caused the program to skip from `data\profile-1` directly to `data\profile-7` and beyond whenever there were six subprocesses per instance. Instances containing seven subprocesses disrupted the sequence entirely, rendering this approach unreliable.

  Second approach: I then tried verifying the availability of each data profile folder prior to launching a new instance by creating a temporary file to detect folder usage. However, Discord does not lock its data directories, so this technique proved infeasible.

  Final solution: I experimented with various `wmic` command combinations to isolate main Discord instances from their subprocesses. I discovered the following:

  `wmic process where name="discord.exe" | find "discord" /c`
  and
  `wmic process where name="discord.exe" | find "dis" /c`

  These commands produced different results. Testing with 1, 2, and 3 instances revealed that searching for "dis" returned the total number of Discord processes across all instances, whereas searching for "discord" returned the same count minus one per instance (representing the main process).

  Using this distinction, it became straightforward to calculate the total number of running Discord instances by subtracting the "discord" count from the "dis" count.

  With this method I achieved a fully portable, multi-instance Discord client that automatically manages separate profiles without conflicts.
