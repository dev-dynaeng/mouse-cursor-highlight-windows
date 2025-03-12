# Check the following video for tutorial on how to use this script
[![Tutorial](https://i.imgur.com/sxbuLpc.jpeg)](https://youtu.be/lpEFMcIbyjg "Tutorial")

## AutoHotkey 2.0 Compatibility

This version of the script has been updated to work with AutoHotkey 2.0. If you're looking for the AutoHotkey 1.0 version, please check the v1.0 branch or tag.

### Key Changes in the AHK 2.0 Version:
- All scripts now use the `#Requires AutoHotkey v2.0` directive
- Map objects (settings) are now accessed using bracket notation `Settings["section"]["property"]`
- Function calls now use parentheses syntax: `FunctionName(param1, param2)`
- GUI code has been updated to use the v2.0 object-based syntax
- Global variables are properly declared in function scope
- Variable references for ByRef parameters use the '&' prefix

## About This Script

This open source code is a handy AutoHotkey script designed for presenters and teachers who need to highlight their mouse pointer. The script has these features: ***highlighting your mouse cursor***, ***keystroke visualization*** and ***on-screen annotation***:

### Mouse Highlight
Highlight mouse pointer with a circle or spotlight, and when you click the mouse button it will display a ring (ripple) animation, so that your audience can follow your mouse easily.

### Keystroke OSD (Keystroke Visualization)
It has a Keystroke OSD that can display the shortcut keys that you have pressed, which can make your audience easier to understand your presentation. 

### On-Screen Annotation
You can use your mouse pointer to annotate any part of the screen. The color and pen of the annotation is customizable through the settings file.

### Show KeyStroke ODS GUI on multiple monitors at same time

To add KeyStroke ODS to a second monitor, you can launch two processes of this program - one process will render the KeyStroke OSD on the main monitor, and also render the click ripples, spotlight and annotation across all monitors. The other process will render the KeyStroke OSD on the second monitor. Here are the steps:

* Step 1: 

Copy all files of this program into a new folder.
<br>

* Step 2:

Go to the new folder and open "settings.ini", then find these lines:
<pre>
[cursorSpotlight]
enabled=True
.. ...
[cursorLeftClickRippleEffect]
enabled=True
... ...
[cursorMiddleClickRippleEffect]
enabled=True
... ...
[cursorRightClickRippleEffect]
enabled=True
... ...
[keyStrokeOSD]
enabled=True
... ...
[annotation]
enabled=True
</pre>
Change all enabled=True to enabled=False except the one in [keyStrokeOSD] section:
<pre>
[cursorSpotlight]
enabled=False
.. ...
[cursorLeftClickRippleEffect]
enabled=False
... ...
[cursorMiddleClickRippleEffect]
enabled=False
... ...
[cursorRightClickRippleEffect]
enabled=False
... ...
[keyStrokeOSD]
enabled=True
... ...
[annotation]
enabled=False
</pre>

* Step 3:

In the "setting.ini" file, find these two lines in the [keyStrokeOSD] section:
<pre>
osdWindowPositionX=760
osdWindowPositionY=540
</pre>
And then change them to the values that fit into your second monitor (sometimes you may have to try negative values to move the OSD onto your second monitor).
<br>

* Step 4:

Save the "setting.ini" file, and then double click the "Start.ahk" to check if the OSD is displayed at the correct position. If not, go back to step 3 to adjust the values -- try increasing or decreasing the values bit by bit to check which direction the OSD window is moving toward and then try guessing the proper values for your second monitor.
<br>

* Step 5:

Go back to the original folder of this program and double click "Start.ahk" to launch the second process for your main monitor.

<br/>
<br/>

# Buy Me a Coffee?
### Donate via [PayPal](https://www.paypal.com/donate/?business=JY46S54HME9LQ&no_recurring=0&currency_code=USD)