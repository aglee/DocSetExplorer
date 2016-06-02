//
//  DSEPrefUtils.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/28/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DSEPrefUtils.h"
#import "DIGSLog.h"

#define DSEDefinePrefName(prefName) static NSString *DSE##prefName##UserDefault = @"DSE"#prefName;
DSEDefinePrefName(DefaultDocSetPath);

@implementation DSEPrefUtils

#pragma mark - Class initialization

+ (void)initialize
{
	// Tell NSUserDefaults the standard values for user preferences.
	[self _registerStandardDefaults];

	// Set logging verbosity, based on user preferences.
	DIGSSetVerbosityLevel( [[NSUserDefaults standardUserDefaults] integerForKey:DIGSLogVerbosityUserDefault]);
}

#pragma mark - Factory methods

+ (instancetype)sharedPrefs
{
	static DSEPrefUtils *s_prefs;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		s_prefs = [[self alloc] init];
	});
	return s_prefs;
}

#pragma mark - App-specific preferences

- (NSString *)defaultDocSetPath
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:DSEDefaultDocSetPathUserDefault];
}

- (void)setDefaultDocSetPath:(NSString *)docSetPath
{
	[[NSUserDefaults standardUserDefaults] setObject:docSetPath forKey:DSEDefaultDocSetPathUserDefault];
	if (![[NSUserDefaults standardUserDefaults] synchronize]) {
		QLog(@"+++ [WARNING] Failed to synchronize NSUserDefaults in %s.", __PRETTY_FUNCTION__);
	}
}

#pragma mark - Private methods

// Register the default values for all user preferences, i.e., the
// value to use for each preference unless the user specifies a
// different one.
+ (void)_registerStandardDefaults
{
	NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];

	defaultPrefs[DIGSLogVerbosityUserDefault] = @(DIGS_VERBOSITY_WARNING);
	defaultPrefs[DSEDefaultDocSetPathUserDefault] = [@"~/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.OSX.docset/" stringByExpandingTildeInPath];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
}

@end
