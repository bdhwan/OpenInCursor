//
//  main.m
//  Open in Code
//
//  Created by Sertac Ozercan on 7/9/2016.
//  Copyright Sertac Ozercan 2016. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

NSString* getPathToFrontFinderWindow(){
	
	SBApplication* finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];
    
	// Get selected items
	NSArray* selection = [finder performSelector:@selector(selection)];
	id target = nil;
	
	if (selection && [selection count] > 0) {
		// Get the first selected item
		target = [[selection firstObject] performSelector:@selector(get)];
	} else {
		// Get the target of the frontmost window
		NSArray* finderWindows = [finder performSelector:@selector(FinderWindows)];
		if (finderWindows && [finderWindows count] > 0) {
			id window = [finderWindows firstObject];
			id windowTarget = [window performSelector:@selector(target)];
			if (windowTarget) {
				target = [windowTarget performSelector:@selector(get)];
			}
		}
	}
	
	if (!target) {
		return [@"~/Desktop" stringByExpandingTildeInPath];
	}
	
	// Get the URL of the target
	NSString* urlString = [target performSelector:@selector(URL)];
	NSURL* url = [NSURL URLWithString:urlString];
	NSError* error;
	NSData* bookmark = [NSURL bookmarkDataWithContentsOfURL:url error:nil];
	NSURL* fullUrl = [NSURL URLByResolvingBookmarkData:bookmark
											options:NSURLBookmarkResolutionWithoutUI
									  relativeToURL:nil
								bookmarkDataIsStale:nil
											  error:&error];
	if(fullUrl != nil){
		url = fullUrl;
	}

	NSString* path = [[url path] stringByExpandingTildeInPath];

	BOOL isDir = NO;
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

	if(!isDir){
		path = [path stringByDeletingLastPathComponent];
	}

	return path;
}

int main(int argc, char *argv[])
{
	id pool = [[NSAutoreleasePool alloc] init];
	
	NSString* path;
	@try{
		path = getPathToFrontFinderWindow();
	}@catch(id ex){
		path =[@"~/Desktop" stringByExpandingTildeInPath];
	}
    
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[@"-n", @"-b" ,@"com.todesktop.230313mzl4w4u92", @"--args", path]] waitUntilExit];
  	
	[pool release];
    return 0;
}
