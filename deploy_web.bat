@echo off
echo Building Flutter web app...
flutter build web

echo Deploying to Firebase Hosting...
firebase deploy --only hosting

echo Deployment complete!
pause