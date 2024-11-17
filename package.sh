# Create the final DMG
create-dmg --volname Astrix --window-size 600 400 --app-drop-link 400 100 --icon 'Applications' 400 100 --icon 'Astrix.app' 100 100 --background ./assets/dmg-background.png Astrix.dmg dist
# Detach the DMG volume
hdiutil detach /Volumes/Astrix
