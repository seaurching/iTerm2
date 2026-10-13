//
//  iTermTipData.m
//  iTerm2
//
//  Created by George Nachman on 6/19/15.
//
//

#import "iTermTipData.h"
#import "iTermTip.h"

@implementation iTermTipData

+ (NSDictionary *)allTips {
  // The keys in this dictionary are saved in user defaults and should not be changed or
  // recycled, or users will see the same tip more than once.
  return @{
    // Big new features
            @"000": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tip of the Day", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 000 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"This window shows the iTerm2 tip of the day. It’ll appear every 24 hours to let you know about new features and hidden secrets. Hit “More Options” to view more tips or to stop getting them altogether.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },
            @"0000": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0000 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The big new feature of iTerm2 version 3 is Shell Integration. Click “Learn More” for all the details.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                          kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0001": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Timestamps", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0001 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"“View > Show Timestamps” shows the time (and date, if appropriate) when each line was last modified.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0002": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Password Manager", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0002 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Did you know iTerm2 has a password manager? Open it with “Window > Password Manager.” You can define a Trigger to open it for you at a password prompt in “Settings > Profiles > Advanced > Triggers.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },
            @"0003": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Open Quickly", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0003 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can quickly search through your sessions with “View > Open Quickly” (⇧⌘O). You can type a query and sessions whose name, badge, current hostname, current user name, recent commands, and recent working directories match will be surfaced. It works best with Shell Integration so the user name, hostname, command, and directories can be known even while sshed.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0004": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Undo Close", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0004 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you close a session, tab, or window by accident you can undo it with “Edit > Undo” (⌘Z). By default you have five seconds to undo, but you can adjust that timeout in “Settings > Profiles > Session.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0005": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Annotations", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0005 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Want to mark up your scrollback history? Right click on a selection and choose “Annotate Selection” to add a personal note to it. Use “View > Show Annotations” to show or hide them, and look in “Edit > Marks and Annotations” for more things you can do.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0006": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Copy with Styles", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0006 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Copy a selection with ⌥⌘C to include styles such as colors and fonts. You can make this the default action for Copy in “Settings > Advanced.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },
            @"0007": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Inline Images", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0007 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"iTerm2 can display images (even animated GIFs) inline.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/images.html" },

            @"0008": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Automatic Profile Switching", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0008 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Automatic Profile Switching changes the current profile when the username, hostname, or directory changes. Set it up in “Settings > Profiles > Advanced.” It requires Shell Integration to be installed.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0009": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Captured Output", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0009 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"iTerm2 can act like an IDE using the Captured Output feature. When it sees text matching a regular expression you define, like compiler errors, it shows the matching lines in the Toolbelt. You can click to jump to the line in your terminal and double-click to perform an action like opening an editor to the line with the error.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/captured_output.html" },

            @"0010": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Badges", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0010 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can display a status message in the top right of your session in the background. It’s called a “Badge.” If you install Shell Integration you can include info like user name, hostname, current directory, and more.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/badges.html" },

            @"0011" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Dynamic Profiles", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0011 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Dynamic Profiles let you store your profiles as one or more JSON files. It’s great for batch creating and editing profiles.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                         kTipUrlKey: @"https://iterm2.com/dynamic-profiles.html" },

            @"0012" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Advanced Paste", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0012 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"“Edit > Paste Special > Advanced Paste” lets you preview and edit text before you paste. You get to tweak options, like how to handle control codes, or even to base-64 encode before pasting.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0013" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Zoom", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0013 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Ever wanted to focus on a block of lines without distraction, or limit Find to a single command’s output? Select the lines and choose “View > Zoom In on Selection.” The session’s contents will be temporarily replaced with the selection. Press “esc” to unzoom.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

    // Big but not new features
            @"0014": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Semantic History", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0014 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The “Semantic History” feature allows you to ⌘-click on a file or URL to open it.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"), },

            @"0015": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tmux Integration", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0015 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you use tmux, try running “tmux -CC” to get iTerm2’s tmux integration mode. The tmux windows show up as native iTerm2 windows, and you can use iTerm2’s keyboard shortcuts. It even works over ssh!", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://gitlab.com/gnachman/iterm2/wikis/TmuxIntegration" },

            @"0016": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Triggers", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0016 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"iTerm2 can automatically perform actions you define when text matching a regular expression is received. For example, you can highlight text or show an alert box. Set it up in “Settings > Profiles > Advanced > Triggers.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://www.iterm2.com/documentation-triggers.html" },

            @"0017": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Smart Selection", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0017 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Quadruple click to perform Smart Selection. It figures out if you’re selecting a URL, filename, email address, etc. based on prioritized regular expressions.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://www.iterm2.com/smartselection.html" },

            @"0018": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Instant Replay", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0018 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Press ⌥⌘B to step back in time in a terminal window. Use arrow keys to go frame by frame. Hold ⇧ and press arrow keys to go faster.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0019": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Hotkey Window", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0019 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can have a terminal window open with a keystroke, even while in other apps. Click “Create a Dedicated Hotkey Window” in “Settings > Keys.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

    // Small things
            @"0020": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Hotkey Window", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0020 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hotkey windows can stay open after losing focus. Turn it on in “Window > Pin Hotkey Window.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0021": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Cursor Guide", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0021 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The cursor guide is a horizontal line that follows your cursor. You can turn it on in “Settings > Profiles > Colors” or toggle it with the ⌥⌘; shortcut.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },  // TODO Add learn more for escape sequence

            @"0022": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration: Alerts", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0022 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The Shell Integration feature lets you ask to be alerted (⌥⌘A) when a long-running command completes.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0023": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Cursor Blink Rate", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0023 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can configure how quickly the cursor blinks in “Settings > Advanced.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0024": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration: Navigation", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0024 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The Shell Integration feature lets you navigate among shell prompts with ⇧⌘↑ and ⇧⌘↓.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0025": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration: Status", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0025 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The Shell Integration feature puts a blue arrow next to your shell prompt. If you run a command that fails, it turns red. Right click on it to get the running time and status.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0026": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration: Selection", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0026 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"With Shell Integration installed, you can select the output of the last command with ⇧⌘A.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0027": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Bells", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0027 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The dock icon shows a count of the number of bells rung and notifications posted since the app was last active.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0028": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration: Downloads", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0028 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you install Shell Integration on a machine you ssh to, you can right click on a filename (for example, in the output of “ls”) and choose “Download with scp” to download the file.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0029": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Find Your Cursor", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0029 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Press ⌘/ to locate your cursor. It’s fun!", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0030": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Customize Smart Selection", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0030 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can edit Smart Selection regular expressions in “Settings > Profiles > Advanced > Smart Selection.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://www.iterm2.com/smartselection.html" },

            @"0031": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Smart Selection Actions", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0031 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Assign an action to a Smart Selection rule in “Settings > Profiles > Advanced > Smart Selection > Edit Actions.” They go in the context menu and override semantic history on ⌘-click.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://www.iterm2.com/smartselection.html" },

            @"0032": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Visual Bell", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0032 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you want the visual bell to flash the whole screen instead of show a bell icon, you can turn that on in “Settings > Advanced.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0033": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tab Menu", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0033 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Right click on a tab to change its color, close tabs after it, or to close all other tabs.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0034": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tags", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0034 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can assign tags to your profiles, and by clicking “Tags>” anywhere you see a list of profiles you can browse those tags.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0035": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tag Hierarchy", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0035 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you put a slash in a profile’s tag, that implicitly defines a hierarchy. You can see it in the Profiles menu as nested submenus.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0036": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Downloads", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0036 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"iTerm2 can download files by base-64 encoding them. Click “Learn More” to download a shell script that makes it easy.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/download.sh" },

            @"0037": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Command Completion", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0037 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you install Shell Integration, ⇧⌘; helps you complete commands. It remembers the commands you’ve run on each host that has Shell Integration installed. It knows how often that command was run and how recently to help make the best suggestions.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0038": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Recent Directories", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0038 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"iTerm2 remembers which directories you use the most on each host that has Shell Integration installed. There’s a Toolbelt tool to browse them, and ⌥⌘/ gives you a popup sorted by frequency and recency of use.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0039": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Favorite Directories", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0039 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you have Shell Integration installed, you can “star” a directory to keep it always at the bottom of the Recent Directories tool in the Toolbelt. Right click and choose “Toggle Star.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0040": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration History", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0040 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Install Shell Integration and turn on “Settings > General > Save copy/paste and command history to disk” to remember command history per host across restarts of iTerm2.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0041": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Paste File as Base64", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0041 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Copy a file to the pasteboard in Finder and then use “Edit > Paste Special > Paste File Base64-Encoded” for easy uploads of binary files. Use ”base64 -D” (or -d on Linux) on the remote host to decode it.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0042": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Split Panes", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0042 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can split a tab into multiple panes with ⌘D and ⇧⌘D.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0043": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Adjust Split Panes", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0043 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Resize split panes with the keyboard using ^⌘-Arrow Key.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0044": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Move Cursor", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0044 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hold ⌥ and click to move your cursor. It works best with Shell Integration installed (to avoid sending up/down arrow keys to your shell).", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0045": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Edge Windows", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0045 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can tell your profile to create windows that are attached to one edge of the screen in “Settings > Profiles > Window.” You can resize them by dragging the edges.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0046": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tab Color", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0046 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can assign colors to tabs in “Settings > Profiles > Colors,” or in the View menu.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0047": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Rectangular Selection", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0047 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hold ⌥⌘ while dragging to make a rectangular selection.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0048": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Multiple Selection", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0048 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hold ⌘ while dragging to make multiple discontinuous selections.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0049": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Dragging Panes", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0049 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hold ⇧⌥⌘ and drag a session into another session to create or change split panes.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0050": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Cursor Boost", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0050 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Adjust Cursor Boost in “Settings > Profiles > Colors” to make all colors more muted, except the cursor. Use a bright white cursor and it pops!", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0051": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Minimum Contrast", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0051 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Adjust “Minimum Contrast” in “Settings > Profiles > Colors” to ensure text is always legible regardless of text/background color combination.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0052": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tabs", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0052 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Normally, new tabs appear at the end of the tab bar. There’s a setting in “Settings > Advanced” to place them next to your current tab.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0053": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Base Conversion", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0053 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Right-click on a number and the context menu shows it converted to hex or decimal as appropriate.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0054": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Saved Searches", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0054 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"In “Settings > Keys” you can assign a keystroke to a search for a regular expression with the “Find Regular Expression…” action.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0055": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Find URLs", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0055 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Search for URLs using “Edit > Find > Find URLs.” Navigate search results with ⌘G and ⇧⌘G. Open the current selection with ⌥⌘O.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0056": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Triggers", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0056 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The “instant” checkbox in a Trigger allows it to fire while the cursor is on the same line as the text that matches your regular expression.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },
            @"0057": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Soft Boundaries", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0057 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Turn on “Edit > Selection Respects Soft Boundaries” to recognize split pane dividers in programs like vi, emacs, and tmux so you can select multiple lines of text.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0058": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Select Without Dragging", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0058 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Single click where you want to start a selection and ⇧-click where you want it to end to select text without dragging.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0059" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Smooth Window Resizing", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0059 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hold ^ while resizing a window and it won’t snap to the character grid: you can make it any size you want.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0060" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Pasting Tabs", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0060 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you paste text containing tabs, you’ll be asked if you want to convert them to spaces. It’s handy at the shell prompt to avoid triggering filename completion.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0061" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Bell Silencing", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0061 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Did you know? If the bell rings too often, you’ll be asked if you’d like to silence it temporarily. iTerm2 cares about your comfort.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0062" : @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Profile Search", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0062 title"),
                         kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Every list of profiles has a search field (e.g., in ”Settings > Profiles.”) You can use various operators to restrict your search query. Click “Learn More” for all the details.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                         kTipUrlKey: @"https://iterm2.com/search_syntax.html" },

            @"0063": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Color Schemes", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0063 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The online color gallery features over one hundred beautiful color schemes you can download.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://www.iterm2.com/colorgallery"},

            @"0064": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"ASCII/Non-Ascii Fonts", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0064 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can have a separate font for ASCII versus non-ASCII text. Enable it in “Settings > Profiles > Text.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0065": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Coprocesses", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0065 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"A coprocess is a job, such as a shell script, that has a special relationship with a particular iTerm2 session. All output in a terminal window (that is, what you see on the screen) is also input to the coprocess. All output from the coprocess acts like text that the user is typing at the keyboard.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/coprocesses.html" },

            @"0066": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Touch Bar Customization", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0066 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can customize the touch bar by selecting “View > Customize Touch Bar.” You can add a tab bar for full-screen mode, a user-customizable status button, and you can even define your own touch bar buttons in Settings > Keys. There’s also a new shell integration tool to customize touch bar function key labels.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0067": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Ligatures", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0067 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you use a font that supports ligatures, you can enable ligature support in Settings > Profiles > Text.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0068": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Floating Hotkey Window", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0068 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"New in 3.1: You can configure your hotkey window to appear over other apps’ full screen windows. Turn on “Floating Window” in “Settings > Profiles > Keys > Customize Hotkey Window.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0069": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Multiple Hotkey Windows", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0069 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"New in 3.1: You can have multiple hotkey windows. Each profile can have one or more hotkeys.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0070": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Double-Tap Hotkey", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0070 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"New in 3.1: You can configure a hotkey window to open on double-tap of a modifier in “Settings > Profiles > Keys > Customize Hotkey Window.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0071": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Buried Sessions", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0071 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can “bury” a session with “Session > Bury Session.” It remains hidden until you restore it by selecting it from “Session > Buried Sessions > Your session.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0072": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Python API", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0072 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can add custom behavior to iTerm2 using the Python API.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/python-api" },

            @"0073": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Status Bar", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0073 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can add a configurable status bar to your terminal windows.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/3.3/documentation-status-bar.html" },

            @"0074": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Minimal Theme", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0074 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Try the “Minimal” and “Compact” themes to reduce visual clutter. You can set it in “Settings > Appearance > General.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0076": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Session Titles", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0076 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can configure which elements are present in session titles in “Settings > Profiles > General > Title.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0077": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Tab Icons", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0077 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Tabs can show an icon indicating the current application. Configure it in “Settings > Profiles > General > Icon.”", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0078": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Drag Window by Tab", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0078 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Hold ⌥ while dragging a tab to move the window. This is useful in the Compact and Minimal themes, which have a very small area for dragging the window.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0079": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Composer", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0079 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Press ⇧⌘. to open the Composer. It gives you a scratchpad to edit a command before sending it to the shell.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },
            
            @"0080": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Shell Integration: Uploads", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0080 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"If you install Shell Integration on a machine you ssh to, you can drag-drop from Finder into the remote host by holding ⌥ while dragging. The destination directory is determined by where you drop the file in the terminal window: run cd foo, then drop the file below the cd command, and the file will go into the foo directory.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/shell_integration.html" },

            @"0081": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Composer Power Features", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0081 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"The composer supports multiple cursors. It also has the ability to send just one command out of a list, making it easy to walk through a list of commands one-by-one. Click the help button in the composer for details.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0082": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Render Selection", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0082 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Transform selected text into a prettified, syntax-highlighted view with the “Render Selection” command, ideal for JSON, Markdown, or source code. This feature includes horizontal scrolling for easy log navigation.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0083": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"SSH Integration", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0083 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Export environment variables and copy files to remote hosts seamlessly with SSH integration. Either configure a profile to use ssh or use it2ssh in place of ssh.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0084": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Auto Composer", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0084 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Improve your command line with the “auto composer”, which replaces the command line with a native control for ease of use. Requires shell integration.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0085": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"AI Command Writing", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0085 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Generate commands using AI by entering a prompt in the composer and selecting “Edit > Engage Artificial Intelligence”. An OpenAI API key is required for this functionality.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0086": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Codecierge Tool", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0086 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Set and achieve terminal goals with “Codecierge”, a Toolbelt feature that guides you step-by-step based on your terminal activity. An OpenAI API key is necessary for this feature.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0087": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Named Marks", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0087 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Navigate your command history effortlessly with “named marks” by assigning names to lines in the terminal.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0088": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Font Assignments", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0088 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can assign specific fonts to Unicode ranges. Use 'Settings > Profiles > Text > Manage Special Exceptions' to manage it and to install a huge set of Powerline symbols.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0089": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Disable Transparency", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0089 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Maintain clarity in your active window while enjoying transparency in background windows by using 'View > Disable transparency in key window'.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0090": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Leader Shortcut", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0090 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Create two-keystroke shortcuts with a “leader”: a special keystroke that precedes a custom key binding.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0091": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Sequence Binding", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0091 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Execute a series of actions in order with a single shortcut using “sequence” key bindings.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0092": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Export/Import Settings", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0092 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Easily backup or transfer your iTerm2 settings using the Export/Import feature in “Settings > General > Settings”.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0093": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Multi-Session Bindings", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0093 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Apply key bindings uniformly across multiple sessions for consistent control in different tabs or windows.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0094": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Inject Trigger", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0094 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Simulate terminal input as if it were output from a running app with the “Inject” trigger.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0095": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Trigger Status Bar", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0095 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Easily manage your triggers using the new Triggers status bar component.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0096": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Session Size in Tab", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0096 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Display session size directly in tab titles for convenient at-a-glance information.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0097": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Advanced Snippet Editing", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0097 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Edit snippets in Advanced Paste by holding the ⌥ key, or open them in the composer with ⇧.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0098": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"HTML Logs", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0098 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Save your terminal logs in HTML format for enhanced readability and sharing capabilities.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0099": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"ASCIICast Logs", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0099 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Create and play back terminal recordings with ASCIICast logs, compatible with asciinema.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0100": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Timestamped Logs", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0100 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Include timestamps in your logs for better tracking and event correlation.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0101": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"LastPass & 1Password", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0101 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Utilize LastPass or 1Password with the password manager by configuring it in the menu next to the search field.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0102": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Password Manager Access", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0102 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Access your password manager without authentication by adjusting the settings via the menu next to its search field.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0103": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Password Generation", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0103 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Generate strong, secure passwords using the password manager’s new password generation feature.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0104": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"it2tip Utility", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0104 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Access tips of the day with the it2tip utility, a command line app. Enable it by installing shell integration and utilities.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0105": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Auto Shell Integration", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0105 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Experience automatic shell integration when creating a login shell, removing the need for explicit setup on your Mac.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0106": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Command Prompt Info", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0106 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Get detailed information about commands by ⌘-clicking on the command prompt.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0107": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"tmux Integration", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0107 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Use tmux integration for automatic key bindings that emulate tmux’s shortcuts, configurable via the Leader settings.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0108": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"tmux Clipboard Mirroring", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0108 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Sync your tmux paste buffer with the local clipboard for seamless integration (requires tmux 3.4).", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0109": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Multi-Cursor in Composer", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0109 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Enhance your editing in the Composer with multiple cursors, created using ^⇧-up/down or ⌥-drag.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0110": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Advanced Paste from Composer", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0110 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Move content from the Composer to the Advanced Paste window with ⌥⌘V for additional editing options.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0111": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Composer Search", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0111 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Search within the Composer using ⌘F to quickly find specific text.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0112": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Resize Composer", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0112 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Adjust the Composer’s height to suit your needs by dragging its bottom edge.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0113": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Explain Command", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0113 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Learn more about your commands by ⌘-clicking in the Composer to open them in explainshell.com.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0114": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Quick Command Send", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0114 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Quickly send and remove commands in the Composer using ⌥⇧-enter.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0115": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Queue Commands", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0115 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Queue up a command in the Composer to be sent after the current command finishes with ⌥-Enter.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0116": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Draggable Tip Window", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0116 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Reposition the Tip of the Day window conveniently on your screen, as it is now draggable.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0117": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"AI Chat", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0117 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"iTerm2 now has an AI Chat feature! Use “Window > AI Chats” or “Edit > Explain Output with AI”. The assistant can interact with your terminal (with your permission) and explain command output, adding annotations right in the terminal.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0118": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Web Browser Profiles", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0118 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"You can configure a profile to be a web browser! In “Settings > Profiles > General”, set “Profile Type” to “Web Browser”. Key bindings, smart selection, and the password manager all work in browser sessions.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body"),
                        kTipUrlKey: @"https://iterm2.com/documentation-web.html" },

            @"0119": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Adjacent Timestamps", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0119 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Timestamps can now be shown next to terminal content instead of overlapping. Configure it in “Settings > Profiles > Session > Timestamps”. Right-click on any line and select “Set Baseline for Relative Timestamps” to see time elapsed between lines.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0120": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Pretty-Print JSON", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0120 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Select a block of JSON text and choose “Edit > Replace Selection > Replace with Pretty-Printed JSON” to make it readable. Perfect for debugging API responses and log files.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0121": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Command Palette", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0121 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Open Quickly (⇧⌘O) is now a command palette! Just type the name of a menu item to activate it.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0122": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"Click Paths in Shell Prompts", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0122 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"Enable “Settings > Profiles > Terminal > Click on a path in a shell prompt to open Navigator” to navigate your filesystem by clicking on paths in your prompt. Requires Shell Integration.", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

            @"0123": @{ kTipTitleKey: NSLocalizedStringFromTableInBundle(@"SSH File Browser", @"Tips", [NSBundle bundleForClass:[self class]], @"tip 0123 title"),
                        kTipBodyKey: NSLocalizedStringFromTableInBundle(@"When connected via SSH Integration, use “Shell > ssh > Download Files” to browse and download files from the remote host without opening a new connection. Files on SSH hosts also appear in file open/save dialogs!", @"Tips", [NSBundle bundleForClass:[self class]], @"tip body") },

// IMPORTANT: When updating this, also update it2tip
            };
}

@end
