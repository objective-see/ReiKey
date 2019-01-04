//
//  utilities.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Sentry;

#import <libproc.h>
#import <sys/sysctl.h>

#import "consts.h"
#import "logging.h"
#import "utilities.h"

//disable std err
void disableSTDERR()
{
    //file handle
    int devNull = -1;
    
    //open /dev/null
    devNull = open("/dev/null", O_RDWR);
    
    //dup
    dup2(devNull, STDERR_FILENO);
    
    //close
    close(devNull);
    
    return;
}

//init crash reporting
void initCrashReporting()
{
    //sentry
    NSBundle *sentry = nil;
    
    //error
    NSError* error = nil;
    
    //class
    Class SentryClient = nil;
    
    //load senty
    sentry = loadFramework(@"Sentry.framework");
    if(nil == sentry)
    {
        //err msg
        logMsg(LOG_ERR, @"failed to load 'Sentry' framework");
        
        //bail
        goto bail;
    }
   
    //get client class
    SentryClient = NSClassFromString(@"SentryClient");
    if(nil == SentryClient)
    {
        //bail
        goto bail;
    }
    
    //set shared client
    [SentryClient setSharedClient:[[SentryClient alloc] initWithDsn:CRASH_REPORTING_URL didFailWithError:&error]];
    if(nil != error)
    {
        //log error
        logMsg(LOG_ERR, [NSString stringWithFormat:@"initializing 'Sentry' failed with %@", error]);
        
        //bail
        goto bail;
    }
    
    //start crash handler
    [[SentryClient sharedClient] startCrashHandlerWithError:&error];
    if(nil != error)
    {
        //log error
        logMsg(LOG_ERR, [NSString stringWithFormat:@"starting 'Sentry' crash handler failed with %@", error]);
        
        //bail
        goto bail;
    }
    
bail:
    
    return;
}

//get app's version
// extracted from Info.plist
NSString* getAppVersion()
{
    //read and return 'CFBundleVersion' from bundle
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

//get path to (main) app of a login item
// login item is in app bundle, so parse up to get main app
NSString* getMainAppPath()
{
    //path components
    NSArray *pathComponents = nil;
    
    //path to config (main) app
    NSString* mainApp = nil;
    
    //get path components
    // then build full path to main app
    pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
    if(pathComponents.count > 4)
    {
        //init path to full (main) app
        mainApp = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count - 4)]];
    }
    
    //when (still) nil
    // use default path
    if(nil == mainApp)
    {
        //default
        mainApp = [@"/Applications" stringByAppendingPathComponent:APP_NAME];
    }
    
    return mainApp;
}

//determine if installed
// simply checks if application exists in /Applications
BOOL isInstalled()
{
    //check if extension exists
    return [[NSFileManager defaultManager] fileExistsAtPath:[APPS_FOLDER stringByAppendingPathComponent:APP_NAME]];
}


//for login item enable/disable
// we use the launch services APIs, since replacements don't always work :(
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

//toggle login item
// either add (install) or remove (uninstall)
BOOL toggleLoginItem(NSURL* loginItem, int toggleFlag)
{
    //flag
    BOOL wasToggled = NO;
    
    //add (install)
    if(ACTION_INSTALL == toggleFlag)
    {
        //always try first remove
        // don't care if this fails
        removeLoginItem(loginItem);
        
        //now add
        wasToggled = addLoginItem(loginItem);
    }
    //remove (uninstall)
    else
    {
        //remove
        wasToggled = removeLoginItem(loginItem);
    }
    
bail:
    
    return wasToggled;
}

//add a login item
BOOL addLoginItem(NSURL* loginItem)
{
    //flag
    BOOL wasAdded = NO;
    
    //login items ref
    LSSharedFileListRef loginItemsRef = NULL;
    
    //login item ref
    LSSharedFileListItemRef loginItemRef = NULL;

    //get reference to login items
    loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"adding login item %@", loginItem]);
        
    //add
    loginItemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)(loginItem), NULL, NULL);
    if(NULL == loginItemRef)
    {
        //bail
        goto bail;
    }
    
    //happy
    wasAdded = YES;
    
bail:
    
    //release item ref
    if(NULL != loginItemRef)
    {
        //release
        CFRelease(loginItemRef);
        
        //reset
        loginItemRef = NULL;
    }
    
    //release login ref
    if(NULL != loginItemsRef)
    {
        //release
        CFRelease(loginItemsRef);
        
        //reset
        loginItemsRef = NULL;
    }

    return wasAdded;
}

//remove a login item
BOOL removeLoginItem(NSURL* loginItem)
{
    //flag
    BOOL wasRemoved = NO;
    
    //login item ref
    LSSharedFileListRef loginItemsRef = NULL;
    
    //login items
    CFArrayRef loginItems = NULL;
    
    //current login item
    CFURLRef currentLoginItem = NULL;
    
    //get reference to login items
    loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"removing login item %@", loginItem]);
    
    //grab existing login items
    loginItems = LSSharedFileListCopySnapshot(loginItemsRef, nil);
    
    //iterate over all login items
    // look for matching one, then remove it
    for(id item in (__bridge NSArray *)loginItems)
    {
        //get current login item
        currentLoginItem = LSSharedFileListItemCopyResolvedURL((__bridge LSSharedFileListItemRef)item, 0, NULL);
        if(NULL == currentLoginItem)
        {
            //skip
            continue;
        }
        
        //current login item match self?
        // full path, or, name match
        if( (YES == [(__bridge NSURL *)currentLoginItem isEqual:loginItem]) ||
            (YES == [((__bridge NSURL *)currentLoginItem).path hasSuffix:loginItem.path.lastPathComponent]) )
        {
            //remove
            if(noErr != LSSharedFileListItemRemove(loginItemsRef, (__bridge LSSharedFileListItemRef)item))
            {
                //err msg
                logMsg(LOG_ERR, @"failed to remove login item");
                
                //bail
                goto bail;
            }
            
            //dbg msg
            logMsg(LOG_DEBUG, [NSString stringWithFormat:@"removed login item: %@", currentLoginItem]);
            
            //happy
            wasRemoved = YES;
            
            //keep going though
        }
        
        //release
        CFRelease(currentLoginItem);
        
        //reset
        currentLoginItem = NULL;
        
    }//all login items
    
bail:
    
    //release login items
    if(NULL != loginItems)
    {
        //release
        CFRelease(loginItems);
        
        //reset
        loginItems = NULL;
    }
    
    //release login ref
    if(NULL != loginItemsRef)
    {
        //release
        CFRelease(loginItemsRef);
        
        //reset
        loginItemsRef = NULL;
    }
    
    //release url
    if(NULL != currentLoginItem)
    {
        //release
        CFRelease(currentLoginItem);
        
        //reset
        currentLoginItem = NULL;
    }
    
    return wasRemoved;
}

#pragma clang diagnostic pop

//exec a process
BOOL execTask(NSString* binaryPath, NSArray* arguments)
{
    //flag
    BOOL wasExec = NO;
    
    //task
    NSTask *task = nil;
    
    //init task
    task = [[NSTask alloc] init];
    
    //set task's path
    task.launchPath = binaryPath;
    
    //set task's args
    if(nil != arguments)
    {
        //add
        task.arguments = arguments;
    }
    
    //dbg msg
    #ifdef DEBUG
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"@exec'ing %@ (args: %@)", binaryPath, arguments]);
    #endif
    
    //wrap task launch
    @try
    {
        //launch
        [task launch];
    }
    @catch(NSException* exception)
    {
        //err msg
        logMsg(LOG_ERR, [NSString stringWithFormat:@"task failed with %@", exception]);
        
        //bail
        goto bail;
    }
    
    //happy
    wasExec = YES;
    
bail:
    
    return wasExec;
}

//get process name
// either via app bundle, or path
NSString* getProcessName(NSString* path)
{
    //process name
    NSString* processName = nil;
    
    //app bundle
    NSBundle* appBundle = nil;
    
    //try find an app bundle
    appBundle = findAppBundle(path);
    if(nil != appBundle)
    {
        //grab name from app's bundle
        processName = [appBundle infoDictionary][@"CFBundleName"];
    }
    
    //still nil?
    // ->just grab from path
    if(nil == processName)
    {
        //from path
        processName = [path lastPathComponent];
    }
    
    return processName;
}

//given a path to binary
// parse it back up to find app's bundle
NSBundle* findAppBundle(NSString* binaryPath)
{
    //app's bundle
    NSBundle* appBundle = nil;
    
    //app's path
    NSString* appPath = nil;
    
    //first just try full path
    appPath = binaryPath;
    
    //try to find the app's bundle/info dictionary
    do
    {
        //try to load app's bundle
        appBundle = [NSBundle bundleWithPath:appPath];
        
        //check for match
        // ->binary path's match
        if( (nil != appBundle) &&
            (YES == [appBundle.executablePath isEqualToString:binaryPath]))
        {
            //all done
            break;
        }
        
        //always unset bundle var since it's being returned
        // ->and at this point, its not a match
        appBundle = nil;
        
        //remove last part
        // ->will try this next
        appPath = [appPath stringByDeletingLastPathComponent];
        
    //scan until we get to root
    // ->of course, loop will exit if app info dictionary is found/loaded
    } while( (nil != appPath) &&
             (YES != [appPath isEqualToString:@"/"]) &&
             (YES != [appPath isEqualToString:@""]) );
    
    return appBundle;
}

//get process's path
NSString* getProcessPath(pid_t pid)
{
    //task path
    NSString* processPath = nil;
    
    //buffer for process path
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE] = {0};
    
    //status
    int status = -1;
    
    //'management info base' array
    int mib[3] = {0};
    
    //system's size for max args
    unsigned long systemMaxArgs = 0;
    
    //process's args
    char* taskArgs = NULL;
    
    //# of args
    int numberOfArgs = 0;
    
    //size of buffers, etc
    size_t size = 0;
    
    //reset buffer
    memset(pathBuffer, 0x0, PROC_PIDPATHINFO_MAXSIZE);
    
    //first attempt to get path via 'proc_pidpath()'
    status = proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));
    if(0 != status)
    {
        //init task's name
        processPath = [NSString stringWithUTF8String:pathBuffer];
    }
    //otherwise
    // try via task's args ('KERN_PROCARGS2')
    else
    {
        //init mib
        // ->want system's size for max args
        mib[0] = CTL_KERN;
        mib[1] = KERN_ARGMAX;
        
        //set size
        size = sizeof(systemMaxArgs);
        
        //get system's size for max args
        if(-1 == sysctl(mib, 2, &systemMaxArgs, &size, NULL, 0))
        {
            //bail
            goto bail;
        }
        
        //alloc space for args
        taskArgs = malloc(systemMaxArgs);
        if(NULL == taskArgs)
        {
            //bail
            goto bail;
        }
        
        //init mib
        // ->want process args
        mib[0] = CTL_KERN;
        mib[1] = KERN_PROCARGS2;
        mib[2] = pid;
        
        //set size
        size = (size_t)systemMaxArgs;
        
        //get process's args
        if(-1 == sysctl(mib, 3, taskArgs, &size, NULL, 0))
        {
            //bail
            goto bail;
        }
        
        //sanity check
        // ensure buffer is somewhat sane
        if(size <= sizeof(int))
        {
            //bail
            goto bail;
        }
        
        //extract number of args
        memcpy(&numberOfArgs, taskArgs, sizeof(numberOfArgs));
        
        //extract task's name
        // follows # of args (int) and is NULL-terminated
        processPath = [NSString stringWithUTF8String:taskArgs + sizeof(int)];
    }
    
bail:
    
    //free process args
    if(NULL != taskArgs)
    {
        //free
        free(taskArgs);
        
        //reset
        taskArgs = NULL;
    }
    
    return processPath;
}

//get an icon for a process
// for apps, this will be app's icon, otherwise just a standard system one
NSImage* getIconForProcess(NSString* path)
{
    //icon's file name
    NSString* iconFile = nil;
    
    //icon's path
    NSString* iconPath = nil;
    
    //icon's path extension
    NSString* iconExtension = nil;
    
    //icon
    NSImage* icon = nil;
    
    //system's document icon
    static NSImage* documentIcon = nil;
    
    //bundle
    NSBundle* appBundle = nil;
    
    //invalid path?
    if(YES != [[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        //bail
        goto bail;
    }
    
    //first try grab bundle
    // ->then extact icon from this
    appBundle = findAppBundle(path);
    if(nil != appBundle)
    {
        //get file
        iconFile = appBundle.infoDictionary[@"CFBundleIconFile"];
        
        //get path extension
        iconExtension = [iconFile pathExtension];
        
        //if its blank (i.e. not specified)
        // go with 'icns'
        if(YES == [iconExtension isEqualTo:@""])
        {
            //set type
            iconExtension = @"icns";
        }
        
        //set full path
        iconPath = [appBundle pathForResource:[iconFile stringByDeletingPathExtension] ofType:iconExtension];
        
        //load it
        icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    }
    
    //process is not an app or couldn't get icon
    // try to get it via shared workspace
    if( (nil == appBundle) ||
        (nil == icon) )
    {
        //extract icon
        icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        
        //load system document icon
        // ->static var, so only load once
        if(nil == documentIcon)
        {
            //load
            documentIcon = [[NSWorkspace sharedWorkspace] iconForFileType:
                            NSFileTypeForHFSTypeCode(kGenericDocumentIcon)];
        }
        
        //if 'iconForFile' method doesn't find and icon, it returns the system 'document' icon
        // the system 'application' icon seems more applicable, so use that here...
        if(YES == [icon isEqual:documentIcon])
        {
            //set icon to system 'applicaiton' icon
            icon = [[NSWorkspace sharedWorkspace]
                    iconForFileType: NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
        }
        
        //'iconForFileType' returns small icons
        [icon setSize:NSMakeSize(128, 128)];
    }
    
bail:
    
    return icon;
}



//wait until a window is non nil
// then make it modal
void makeModal(NSWindowController* windowController)
{
    //wait up to 1 second window to be non-nil
    // then make modal
    for(int i=0; i<20; i++)
    {
        //can make it modal once we have a window
        if(nil != windowController.window)
        {
            //make modal on main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                //modal
                [[NSApplication sharedApplication] runModalForWindow:windowController.window];
                
            });
            
            //all done
            break;
        }
        
        //nap
        [NSThread sleepForTimeInterval:0.05f];
        
    }//until 1 second
    
    return;
}

//path to login item
NSString* loginItemPath()
{
    //init path to login item app
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/Contents/Library/LoginItems/%@.app", LOGIN_ITEM_NAME]];
}

//start app
// note: executed with 'NSWorkspaceLaunchWithoutActivation'
BOOL startApplication(NSURL* path, NSUInteger launchOptions)
{
    //status var
    BOOL result = NO;
    
    //error
    NSError* error = nil;
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"starting application: %@", path]);
    
    //launch it
    if(nil == [[NSWorkspace sharedWorkspace] launchApplicationAtURL:path options:launchOptions configuration:@{} error:&error])
    {
        //err msg
        logMsg(LOG_ERR, [NSString stringWithFormat:@"failed to application: %@/%@", path, error]);
        
        //bail
        goto bail;
    }
    
    //happy
    result = YES;
    
bail:
    
    return result;
}

//check if process is alive
BOOL isProcessAlive(pid_t processID)
{
    //ret var
    BOOL bIsAlive = NO;
    
    //signal status
    int signalStatus = -1;
    
    //send kill with 0 to determine if alive
    signalStatus = kill(processID, 0);
    
    //is alive?
    if( (0 == signalStatus) ||
       ((0 != signalStatus) && (errno != ESRCH)) )
    {
        //alive!
        bIsAlive = YES;
    }
    
    return bIsAlive;
}


//loads a framework
// note: assumes it is in 'Framework' dir
NSBundle* loadFramework(NSString* name)
{
    //handle
    NSBundle* framework = nil;
    
    //framework path
    NSString* path = nil;
    
    //init path
    path = [NSString stringWithFormat:@"%@/../Frameworks/%@", [NSProcessInfo.processInfo.arguments[0] stringByDeletingLastPathComponent], name];
    
    //standardize path
    path = [path stringByStandardizingPath];
    
    //init framework (bundle)
    framework = [NSBundle bundleWithPath:path];
    if(NULL == framework)
    {
        //bail
        goto bail;
    }
    
    //load framework
    if(YES != [framework loadAndReturnError:nil])
    {
        //bail
        goto bail;
    }
    
bail:
    
    return framework;
}

//transform app state
OSStatus transformApp(ProcessApplicationTransformState newState)
{
    //serial number
    // init with current process
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    
    //transform and return
    return TransformProcessType(&psn, newState);
}


//check if (full) dark mode
// meaning, Mojave+ and dark mode enabled
BOOL isDarkMode()
{
    //flag
    BOOL darkMode = NO;
    
    //not mojave?
    // bail, since not true dark mode
    if(YES != [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 14, 0}])
    {
        //bail
        goto bail;
    }
    
    //not dark mode?
    if(YES != [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"])
    {
        //bail
        goto bail;
    }
    
    //ok, mojave dark mode it is!
    darkMode = YES;
    
bail:
    
    return darkMode;
}

//prettify JSON
NSString* prettifyJSON(NSString* output)
{
    //data
    NSData* data = nil;
    
    //object
    id object = nil;
    
    //pretty data
    NSData* prettyData = nil;
    
    //pretty string
    NSString* prettyString = nil;
    
    //covert to data
    data = [output dataUsingEncoding:NSUTF8StringEncoding];
    
    //convert to JSON
    // wrap since we are serializing JSON
    @try
    {
        //serialize
        object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        //covert to pretty data
        prettyData =  [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    }
    @catch(NSException *exception)
    {
        ;
    }
    
    //covert to pretty string
    if(nil != prettyData)
    {
        //convert to string
        prettyString = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
    }
    else
    {
        //error
        prettyString = @"{\"ERROR\" : \"failed to covert output to JSON\"}";
    }
    
    return prettyString;
}
