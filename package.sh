# Setup folders
rm -rf ./dist
rm -rf ./build
rm -rf ./Astrix.dmg
mkdir ./dist
# build the xcode app
xcodebuild -project Astrix.xcodeproj -alltargets -configuration Release
# archive the app into 1 .app file in the dist folder
cp -r ./build/Release/Astrix.app ./dist/Astrix.app
# Create the final DMG
create-dmg --volname Astrix --window-size 600 400 --app-drop-link 400 100 --icon 'Applications' 400 100 --icon 'Astrix.app' 100 100 --background ./assets/dmg-background.png Astrix.dmg dist
