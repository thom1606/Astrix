export AWS_ACCESS_KEY_ID=e5b8b003175c0eca529ae540841db6e3
export AWS_SECRET_ACCESS_KEY=11c6cd7af0502b1d75df94f76c9460e2ebd99fea6120cadcc89774e51fc64e8b

# TODO: Change the version to the latest version
# TODO: Change the file names to the latest version
# TODO: add package script to the release
# TODO: update appcast.xml
# TODO: notify user to update the appcast.xml in website

aws s3 cp Astrix-1.6-release.dmg \
  s3://public-sharebox/Astrix-1.6-release.dmg \
  --endpoint-url https://1b95f1ca2f88b09af06c8f808ceb2f6e.r2.cloudflarestorage.com \
  --content-type application/x-apple-diskimage \
  --content-disposition 'attachment; filename="Astrix 1.6.dmg"'

aws s3 cp Astrix-1.6-app.zip \
  s3://public-sharebox/Astrix-1.6-app.zip \
  --endpoint-url https://1b95f1ca2f88b09af06c8f808ceb2f6e.r2.cloudflarestorage.com \
  --content-type application/zip \
  --content-disposition 'attachment; filename="Astrix 1.6.zip"'

