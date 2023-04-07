![Untitled](https://user-images.githubusercontent.com/63984796/183294294-e048e64a-24ef-4fed-b69f-fe3963813dd1.png)
# ScriptWriter-Plugin
A simple plugin to virtually type out scripts for making tutorial videos.  You can set some settings in the plugin.gd script such as `CPM` (characters per minute) and `PAUSE_BETWEEN` (amount of time to pause between writing blocks).  Note: this turns script autocomplete off before starting, and back on after finishing.  Thus, if you exit out of the editor or disable the plugin while it is writing, your autocomplete will remain off until you go to Editor Settings > Text Editor > Completion.

Once enabled, you can use the following commands to use the plugin:
### Commands:

1. `#/from` saves the current script as the `from_script`. IE the script that will be written to the `to_script`. This saves the text, not the file.
2. `#/to` writes the from script to the current script.  This clears the current script.
3. `#/clear` clears the current script.  Be careful, this cannot be undone with `ctrl+z` / `cmd+z`
4. `#/` + `integer` divides the from script into blocks (optional). Every line below these commands until another block command is encountered will be included in this block. Thus, you can have several different secions written in the order of the integer provided.

#### FROM EXAMPLE
![FromGIF](https://user-images.githubusercontent.com/63984796/183295415-3c0ec526-9e9f-45af-bc18-3cc06caeb971.gif) 
#### TO EXAMPLE
![ToGIF](https://user-images.githubusercontent.com/63984796/183295648-db4a5b86-1e66-4cca-923f-5b39b560fd95.gif)

