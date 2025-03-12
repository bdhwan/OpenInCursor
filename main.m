//
//  main.m
//  Open in Code
//
//  Created by Sertac Ozercan on 7/9/2016.
//  Copyright Sertac Ozercan 2016. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Finder.h"

NSString* getPathToFrontFinderWindow(){
	
	// Log to console for debugging
	NSLog(@"Getting path to front Finder window");
	
	FinderApplication* finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];
	if (!finder) {
		NSLog(@"Failed to get Finder application");
		return [@"~/Desktop" stringByExpandingTildeInPath];
	}
	
	NSLog(@"Got Finder application");
	
	// Get selection with error handling
	NSArray* selectionArray = nil;
	@try {
		selectionArray = [[finder selection] get];
		NSLog(@"Selection array: %@", selectionArray);
	} @catch (NSException *exception) {
		NSLog(@"Exception getting selection: %@", exception);
	}
	
	FinderItem *target = nil;
	
	// Try to get the selected item first
	if (selectionArray && [selectionArray count] > 0) {
		target = [selectionArray firstObject];
		NSLog(@"Got target from selection");
	} else {
		NSLog(@"No selection, trying to get front window target");
		// No selection, try to get the target of the front Finder window
		@try {
			// Get the first Finder window and its target
			NSArray *finderWindows = [finder FinderWindows];
			if (finderWindows && [finderWindows count] > 0) {
				FinderFinderWindow *window = [finderWindows firstObject];
				if (window) {
					target = [[window target] get];
					NSLog(@"Got target from front window");
				} else {
					NSLog(@"First window is nil");
				}
			} else {
				NSLog(@"No Finder windows found");
			}
		} @catch (NSException *exception) {
			NSLog(@"Exception getting window target: %@", exception);
		}
	}
	
	// If we couldn't get a target, return the Desktop path
	if (!target) {
		NSLog(@"Failed to get target, returning Desktop");
		return [@"~/Desktop" stringByExpandingTildeInPath];
	}
	
	// Get the URL of the target
	NSString* urlString = target.URL;
	NSLog(@"Target URL string: %@", urlString);
	
	if (!urlString || [urlString length] == 0) {
		NSLog(@"Empty URL string, returning Desktop");
		return [@"~/Desktop" stringByExpandingTildeInPath];
	}
	
	NSURL* url = [NSURL URLWithString:urlString];
	if (!url) {
		NSLog(@"Failed to create URL from string, returning Desktop");
		return [@"~/Desktop" stringByExpandingTildeInPath];
	}
	
	NSError* error = nil;
	NSData* bookmark = [NSURL bookmarkDataWithContentsOfURL:url error:&error];
	
	if (error) {
		NSLog(@"Error creating bookmark data: %@", error);
	}
	
	if (bookmark) {
		BOOL isStale = NO;
		NSURL* fullUrl = [NSURL URLByResolvingBookmarkData:bookmark
												   options:NSURLBookmarkResolutionWithoutUI
											 relativeToURL:nil
										   bookmarkDataIsStale:&isStale
												     error:&error];
		if (error) {
			NSLog(@"Error resolving bookmark: %@", error);
		}
		
		if (fullUrl) {
			url = fullUrl;
			NSLog(@"Using resolved URL: %@", fullUrl);
		}
	}
	
	NSString* path = [[url path] stringByExpandingTildeInPath];
	NSLog(@"Path from URL: %@", path);
	
	// Check if it's a directory
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	
	if (!exists) {
		NSLog(@"Path does not exist, returning Desktop");
		return [@"~/Desktop" stringByExpandingTildeInPath];
	}
	
	// If it's a file, get its parent directory
	if (!isDir) {
		NSLog(@"Path is a file, getting parent directory");
		path = [path stringByDeletingLastPathComponent];
	}
	
	NSLog(@"Final path: %@", path);
	return path;
}

int main(int argc, char *argv[])
{
	id pool = [[NSAutoreleasePool alloc] init];
	
	NSString* path;
	@try{
		path = getPathToFrontFinderWindow();
	}@catch(id ex){
		NSLog(@"Exception in getPathToFrontFinderWindow: %@", ex);
		path =[@"~/Desktop" stringByExpandingTildeInPath];
	}
    
    NSLog(@"Opening Cursor with path: %@", path);
    
    // Create a task to run Cursor
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/open"];
    [task setArguments:@[@"-n", @"-b", @"com.todesktop.230313mzl4w4u92", @"--args", path]];
    
    // Set up a pipe to capture the output
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    
    // Start the task
    NSLog(@"Launching task with arguments: %@", [task arguments]);
    [task launch];
    
    // Capture the output
    NSFileHandle *file = [pipe fileHandleForReading];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Task output: %@", output);
    [output release];
    
    // Wait for the task to finish
    [task waitUntilExit];
    
    // Log exit status
    int status = [task terminationStatus];
    NSLog(@"Task completed with status: %d", status);
    
    [task release];
    
	[pool release];
    return 0;
}
