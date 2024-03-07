#!/bin/bash
#
# notarize.sh
# Gravity
#
# Sulaiman Ghori
#
# The purpose of this script is to notarize the Gravity app for distribution


# First, the app is archived. We will do this manually for now, so ask the user to do it.
# echo "Please archive and notarize the app in Xcode and then press enter to continue"
# read

# Next, we will package the app for in a DMG for distribution
# echo "Please package the app in a DMG and then press enter to continue"
# read

# Next, we will sign the DMG and update the appcast.xml

~/Library/Developer/Xcode/DerivedData/Invisibility-hbxvwrwlvyhqhlgbsizwyhkkhzac/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast ~/github/invisibility_inc/App/Invisibility
