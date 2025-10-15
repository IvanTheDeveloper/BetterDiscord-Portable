## Notice of Non-Affiliation and Disclaimer

This project is not affiliated with, associated with, authorized by, endorsed by, or in any way officially connected to [**Discord™**](https://discordapp.com), [**Portapps**](https://portapps.io/app/discord-portable), or [**BetterDiscord**](https://betterdiscord.app), or any of their subsidiaries or affiliates.

The names **Discord™**, **Portapps**, and **BetterDiscord**, as well as related names, marks, emblems and images, are registered trademarks of their respective owners.

## FAQ

- **What does this do?**

  This project mimics Portapps approach while keeping updates working. The Electron userData path is forced to the data folder inside the portable root. Additionally, the injection is repatched on launch if it gets removed after an automatic update.

- **Why don't you use the Discord portable made by Portapps?**

  Discord portable and BetterDiscord are incompatible with each other. Installing BetterDiscord on the Portapps build is technically possible, but causes Discord to break after the first launch. Full explanation below.

- **For all BetterDiscord-related questions (PTB / Canary compatibility, ban risk, etc.), please refer to the BetterDiscord project page.**

## Technical Background (Summary)

### Understanding the problem

In the Discord installation root, under `<discord-root>/app-<version>/resources`, there is a file called `app.asar` that contains much of Discord's runtime code.

In the Portapps version of Discord, however, the app content is an unwrapped folder (named `app/`) instead of an .asar archive.  
This happens because Portapps makes Discord portable by decompiling the `app.asar` file and modifying the default data path variables.

When BetterDiscord is installed on a Portapps portable build and the app runs, something in the shutdown/cleanup process causes the `app/` folder to be removed.  
BetterDiscord itself does not directly delete these files, but its presence changes the behavior of the Portapps client in a way that indirectly triggers this removal.

BetterDiscord modifies a single file in the base Discord installation:

`<discord-root>\app-<version>\modules\discord_desktop_core-1\discord_desktop_core\index.js`

— it adds a line that references an additional file called `betterdiscord.asar` located within BetterDiscord's data folder which contains its libraries and code.

### My approaches and solution

First attempt (restoring the removed files at launch).
I stored a copy of the `app/` folder in the portable root and made the launcher copy it back into place before launching Discord. This worked but felt hacky, prevented easy updates, and introduced downsides when trying to move to newer Discord versions.

Second attempt (use normal installer files)
I tried updating the old version app files to a newer release, which came with the `app.asar` file so Discord would not self-destruct after BetterDiscord installation. That fixed the issue but made Discord stop using the portable root `data/` folder and instead wrote to `%APPDATA%` (like a normal install) since the patch got removed in the update. This meant it was no longer truly portable.

Final approach (portable launcher using environment variable)
I created a small launcher script (a .bat file) that sets the Electron userData path environment variable to the portable root `data/` directory before launching Discord, without modifying the code. This made Discord (and BetterDiscord) use the portable `data/` folder. I also relocated the `betterdiscord.asar` file to the root so it would not be stored inside the `data/` folder (this folder is generated at runtime and should not be uploaded to the repo).

With this method I achieved a fully portable and updatable Discord that supports BetterDiscord.
