//
//  utilities.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#ifndef utilities_h
#define utilities_h

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

/* FUNCTIONS */

//disable std err
void disableSTDERR(void);

//init crash reporting
void initCrashReporting(void);

//get app's version
// extracted from Info.plist
NSString* getAppVersion(void);

//determine if installed
// simply checks if application exists in /Applications or ~/Applications
BOOL isInstalled(void);

//path to installed app
// if admin: /Applications/<app name>
// if user:  ~/Applications/<app name>
NSString* appPath(void);

//given a path to binary
// parse it back up to find app's bundle
NSBundle* findAppBundle(NSString* binaryPath);

//get process's path
NSString* getProcessPath(pid_t pid);

//path to login item
NSString* loginItemPath(void);

//get process name
// either via app bundle, or path
NSString* getProcessName(NSString* path);

//given a process path and user
// return array of all matching pids
NSMutableArray* getProcessIDs(NSString* processPath, int userID);

//given a pid, get its parent (ppid)
pid_t getParentID(int pid);

//enable/disable a menu
void toggleMenu(NSMenu* menu, BOOL shouldEnable);

//toggle login item
// either add (install) or remove (uninstall)
BOOL toggleLoginItem(NSURL* loginItem, int toggleFlag);

//add a login item
BOOL addLoginItem(NSURL* loginItem);

//remove a login item
BOOL removeLoginItem(NSURL* loginItem);

//start app
BOOL startApplication(NSURL* appPath, NSUInteger launchOptions);

//get an icon for a process
// for apps, this will be app's icon, otherwise just a standard system one
NSImage* getIconForProcess(NSString* path);

//wait until a window is non nil
// then make it modal
void makeModal(NSWindowController* windowController);

//find a process by name
pid_t findProcess(NSString* processName);

//exec a process
BOOL execTask(NSString* binaryPath, NSArray* arguments, BOOL wait);

//extract a DNS name
NSMutableString* extractDNSName(unsigned char* start, unsigned char* chunk, unsigned char* end);

//loads a framework
// note: assumes is in 'Framework' dir
NSBundle* loadFramework(NSString* name);

//restart
void restart(void);

//bring an app to foreground
// based on: https://stackoverflow.com/questions/7596643/when-calling-transformprocesstype-the-app-menu-doesnt-show-up
void foregroundApp(void);

//send an app to the background
void backgroundApp(void);

//transform app state
OSStatus transformApp(ProcessApplicationTransformState newState);

//check if (full) dark mode
// meaning, Mojave+ and dark mode enabled
BOOL isDarkMode(void);

//check if process is alive
BOOL isProcessAlive(pid_t processID);

//prettify JSON
NSString* prettifyJSON(NSString* output);

#endif
