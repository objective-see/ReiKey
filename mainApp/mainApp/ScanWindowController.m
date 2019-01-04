//
//  ScanWindowController.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "consts.h"
#import "logging.h"
#import "ScanRow.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "ScanWindowController.h"

@implementation ScanWindowController

@synthesize tapID;
@synthesize rules;
@synthesize toolbar;
@synthesize searchBox;
@synthesize eventTaps;
@synthesize eventTapsObj;

//prep UI for scan
// show overlay, etc...
-(void)preScan
{
    //unset
    self.eventTaps = nil;
    
    //reload table to clear
    [self.tableView reloadData];
    
    //pre-req for color of overlay
    self.overlay.wantsLayer = YES;
    
    //round overlay's corners
    self.overlay.layer.cornerRadius = 20.0;
    
    //mask overlay
    self.overlay.layer.masksToBounds = YES;
    
    //dark mode
    // set overlay to light
    if(YES == isDarkMode())
    {
        //set overlay's view color to gray
        self.overlay.layer.backgroundColor = NSColor.lightGrayColor.CGColor;
    }
    //light mode
    // set overlay to gray
    else
    {
        //set to gray
        self.overlay.layer.backgroundColor = NSColor.grayColor.CGColor;
    }
    
    //disable scan button
    self.rescan.enabled = NO;
    
    //show overlay
    self.overlay.hidden = NO;
    
    //start activity indicator
    [self.activityIndicator startAnimation:nil];
    
    return;
}

//'refresh/rescan' button handler
// can also call directly to scan...
-(IBAction)reScan:(id)sender
{
    //setup UI for scan
    [self preScan];
    
    //kick off scan in background
    // will reload table with results when done
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
       
       //start
       [self scan];
       
    });

    return;
}

//(re)scan
// then reload table
-(void)scan
{
    //alloc/init event tap obj
    if(nil == self.eventTapsObj)
    {
        //init
        eventTapsObj = [[EventTaps alloc] init];
    }
    
    //enumerate existing taps
    self.eventTaps = [[eventTapsObj enumerate] allValues];
    
    //on main thread
    // show results (i.e. keyboard taps)
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //nap
        // allow overlay to show...
        [NSThread sleepForTimeInterval:1.0];
        
        //show results
        [self displayResults];
        
    });
    
    return;
}

//hide overlay
// reload table, etc.
-(void)displayResults
{
    //flag
    BOOL selectedRow = NO;
    
    //hide overlay
    self.overlay.hidden = YES;
    
    //enable scan button
    self.rescan.enabled = YES;

    //reload table
    [self.tableView reloadData];
    
    //was a tap id specified to select?
    if(nil != self.tapID)
    {
        //find matching
        // use index, cuz, need index to select row
        for(NSUInteger index = 0; index < self.eventTaps.count; index++)
        {
            //match?
            if([self.eventTaps[index][TAP_ID] integerValue] == [self.tapID integerValue])
            {
                //select
                [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];

                //set flag
                selectedRow = YES;
                
                //done
                break;
            }
        }
        
        //unset
        // (rescans) should default back to selecting first row
        self.tapID = nil;
    }
    
    //no row (manually) selected?
    // just select first
    if(YES != selectedRow)
    {
        //select first row
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    
    return;
}

#pragma mark -
#pragma mark table delegate methods

//number of rows
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    //count
    return self.eventTaps.count;
}

//cell for (each) table column
-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //cell
    NSTableCellView *tableCell = nil;
    
    //event tap
    NSMutableDictionary* eventTap = nil;
    
    //process name
    NSString* processName = nil;
    
    //process path
    NSString* processPath = nil;
    
    //process icon
    NSImage* processIcon = nil;
    
    //sanity check
    if(row >= self.eventTaps.count)
    {
        //bail
        goto bail;
    }
    
    //get event tap
    eventTap = self.eventTaps[row];
    
    //column: 'process'
    if(tableColumn == tableView.tableColumns[0])
    {
        //grab process path
        processPath = eventTap[TAP_SOURCE_PATH];
        
        //set process name
        processName = [processPath lastPathComponent];
        
        //set icon
        processIcon = getIconForProcess(processPath);
        
        //init table cell
        tableCell = [tableView makeViewWithIdentifier:@"tappingCell" owner:self];
        if(nil == tableCell)
        {
            //bail
            goto bail;
        }
        
        //set icon
        tableCell.imageView.image = processIcon;
        
        //set (main) text
        // process name (device)
        tableCell.textField.stringValue = [NSString stringWithFormat:@"%@ (%@)", processName, eventTap[TAP_SOURCE_PID]];
        
        //set sub text
        [[tableCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG] setStringValue:processPath];
        
        //set detailed text color to gray
        ((NSTextField*)[tableCell viewWithTag:TABLE_ROW_SUB_TEXT_TAG]).textColor = [NSColor secondaryLabelColor];
        
    } //1st column

    //column: 'target process'
    else if(tableColumn == tableView.tableColumns[1])
    {
        //init table cell
        tableCell = [tableView makeViewWithIdentifier:@"targetCell" owner:self];
        if(nil == tableCell)
        {
            //bail
            goto bail;
        }
        
        //grab process path
        processPath = eventTap[TAP_DESTINATION_PATH];
        
        //system wide tap?
        if(YES == [processPath isEqualToString:GLOBAL_EVENT_TAP])
        {
            //set text
            tableCell.textField.stringValue = GLOBAL_EVENT_TAP;
        }
        //specific process tap
        else
        {
            //set text
            tableCell.textField.stringValue = [NSString stringWithFormat:@"%@ (pid: %@)", eventTap[TAP_DESTINATION_PATH], eventTap[TAP_DESTINATION_PID]];
        }
        
        //all set
        goto bail;
    
    } //2nd column
    
    //column: 'type'
    else
    {
        //init table cell
        tableCell = [tableView makeViewWithIdentifier:@"typeCell" owner:self];
        if(nil == tableCell)
        {
            //bail
            goto bail;
        }
        
        //set type
        tableCell.textField.stringValue = eventTap[TAP_OPTIONS];
        
    } //3rd column
    
bail:
    
    return tableCell;
}

//row for view
-(NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    //row view
    ScanRow* rowView = nil;
    
    //row ID
    static NSString* const kRowIdentifier = @"RowView";
    
    //try grab existing row view
    rowView = [tableView makeViewWithIdentifier:kRowIdentifier owner:self];
    
    //make new if needed
    if(nil == rowView)
    {
        //create new
        // ->size doesn't matter
        rowView = [[ScanRow alloc] initWithFrame:NSZeroRect];
        
        //set row ID
        rowView.identifier = kRowIdentifier;
    }
    
    return rowView;
}

@end
