//
//  consts.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#ifndef consts_h
#define consts_h

//install cmd
#define CMD_INSTALL @"-install"

//uninstall cmd
#define CMD_UNINSTALL @"-uninstall"

//button install
#define UI_INSTALL @"Install"

//button uninstall
#define UI_UNINSTALL @"Uninstall"

//button title
#define UI_CLOSE @"Close"

//button title
#define UI_NEXT @"Next »"

//button title
#define UI_NO @"No"

//button title
#define UI_YES @"Yes!"

//flag to uninstall
#define ACTION_UNINSTALL 0

//flag to install
#define ACTION_INSTALL 1

//flag for partial uninstall
#define UNINSTALL_PARTIAL 0

//flag for full uninstall
#define UNINSTALL_FULL 1

//system applications
#define SYSTEM_APPS_FOLDER @"/Applications"

//user applications
#define USER_APPS_FOLDER @"~/Applications"

//path to killall
#define KILL @"/usr/bin/killall"

//path to xattr
#define XATTR @"/usr/bin/xattr"

//suite name
// for shared preferences
#define SUITE_NAME @"com.objective-see.reikey.group"

//main app bundle id
#define APP_BUNDLE_ID @"com.objective-see.reikey"

//login item bundle id
#define LOGIN_ITEM_BUNDLE_ID @"com.objective-see.reikey.helper"

//showed splash screen
#define SHOWED_SPLASH @"showedSplash"

//showed status bar popup
#define SHOWED_POPUP @"showedPopup"

//muted items (paths)
#define MUTED_ITEMS @"mutedItems"

//prefs changed notification
#define NOTIFICATION_PREFS_CHANGED @"com.objective-see.reikey.preferences"

//patreon url
#define PATREON_URL @"https://www.patreon.com/bePatron?c=701171"

//sentry crash reporting URL
#define CRASH_REPORTING_URL @"https://cc60a04750ff4daeaa2d0d9e090e21c7@sentry.io/1360726"

//signing auth
#define SIGNING_AUTH @"Developer ID Application: Objective-See, LLC (VBG97UB4TA)"

//product url
#define PRODUCT_URL @"https://objective-see.com/products/reikey.html"

//product version url
#define PRODUCT_VERSIONS_URL @"https://objective-see.com/products.json"

//error(s) url
#define ERRORS_URL @"https://objective-see.com/errors.html"

//support us button tag
#define BUTTON_SUPPORT_US 100

//more info button tag
#define BUTTON_MORE_INFO 101

//login item name
#define LOGIN_ITEM_NAME @"ReiKey Helper"

//prefs
// disabled status
#define PREF_IS_DISABLED @"disabled"

//prefs
// start at login
#define PREF_START_AT_LOGIN @"startAtLogin"

//prefs
// start at login
#define PREF_SHOW_AT_LOGIN @"showAtLogin"

//prefs
// run with icon
#define PREF_RUN_WITH_ICON @"runWithIcon"

//prefs
// ignore apple binaries
#define PREF_IGNORE_APPLE_BINS @"ignoreAppleBins"

//pref
// disable update check
#define PREF_NO_UPDATES @"noUpdates"

//app name
#define APP_NAME @"ReiKey.app"

//cmdline flag
#define CMDLINE_FLAG_SCAN @"-scan"

//all procs
#define GLOBAL_EVENT_TAP @"All processes"

//tap id
#define TAP_ID @"tapID"

//tap options
#define TAP_OPTIONS @"tapOptions"

//tap source path
#define TAP_SOURCE_PATH @"sourcePath"

//tap source pid
#define TAP_SOURCE_PID @"sourcePID"

//tap destination path
#define TAP_DESTINATION_PATH @"destinationPath"

//tap destination pid
#define TAP_DESTINATION_PID @"destinationPID"

//product name
// ...for version check
#define PRODUCT_NAME @"ReiKey"

//product version url
#define PRODUCT_VERSIONS_URL @"https://objective-see.com/products.json"

//update error
#define UPDATE_ERROR -1

//update no new version
#define UPDATE_NOTHING_NEW 0

//update new version
#define UPDATE_NEW_VERSION 1

//signers
enum Signer{None, Apple, AppStore, DevID, AdHoc};

//signature status
#define KEY_SIGNATURE_STATUS @"signatureStatus"

//signer
#define KEY_SIGNATURE_SIGNER @"signatureSigner"

//signing auths
#define KEY_SIGNATURE_AUTHORITIES @"signatureAuthorities"

//code signing id
#define KEY_SIGNATURE_IDENTIFIER @"signatureIdentifier"

//entitlements
#define KEY_SIGNATURE_ENTITLEMENTS @"signatureEntitlements"

//dismiss alert
#define ALERT_DISMISS 0

//details alert
#define ALERT_DETAILS 1

#endif /* const_h */
