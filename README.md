# Source Chatter
![Showcase](https://bitbucket.org/Phil25/sourcechattermedia/raw/2a4d03d6f60325fc1c9dec5415a88763a9d78c88/SourceChatter02.gif)

# Description [^](#source-chatter)
Source Chatter allows you to monitor and interact with chat and scoreboard of your servers through the browser. After you log in through Steam and have access, you may see everything, chat along and issue commands with respect for SourceMod admin flags.

# Features [^](#source-chatter)
* Logging in through Steam used as authentication.
* Manually add users with access.
* Supports arbitrary amount of servers.
* Messages stored in database, allowing for showing short history after joining.
* Automatic clean up: every 5 minutes, messages older than 5 minutes are deleted.
* Updater support for the plugin.
* Live chat feed:
	* Join in with your actual Steam name, and defined tag.
	* Displaying some core events, such as players joining or name changing.
	* Plugins can push their own messages with BBCode support.
	* Custom Chat Colors support.
* Live scoreboard:
	* Showing avatar, name, country code, statuses, user ID, class (TF2), score and ping.
	* Statuses are: is dead, is in group (optional), is voicechatting (upcoming)
	* Team colored (TF2 default, may be altered).
	* Names linked to steamcommunity accounts for easy access.
	* Players ordered by team and score, replicating the in-game scoreboard.
* Commands:
	* Type in commands with ! or /, where / hides your message.
	* Commands respect SourceMod admin flags, that are assigned to the user.
	* Responses are feedbacked in the field below the chat.

# Requirements [^](#source-chatter)
* SourceMod 1.9+
* Webserver with PHP 5+ and MySQL database
* Event Scheduler enabled in the database

## Installation guide, developer information and more are all available in the [AlliedModders thread](https://forums.alliedmods.net/showthread.php?t=310211).
