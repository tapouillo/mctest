//
//  AppDelegate.m
//  mctest
//
//  Created by Stéphane QUERAUD on 18/07/2015.
//  Copyright (c) 2015 Stéphane QUERAUD. All rights reserved.
//

#import "AppDelegate.h"
#import "sharedGNP.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMailCount:) name:@"newTotalMailCount" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLatestEmails:) name:@"newEmails" object:nil];
    
    
    
    sharedGNP *shared = [sharedGNP sharedInstance];
    
    [shared initAll];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void) updateLatestEmails:(NSNotification *) notification
{
    NSDictionary* userInfo = notification.userInfo;
    NSArray *ar = (NSArray *)[userInfo objectForKey:@"fetchedMessage"];
    NSString *accountNameInfo = (NSString *)[userInfo objectForKey:@"accountEmail"];
    
    
    sharedGNP *shared = [sharedGNP sharedInstance];
    
   
    for (emailAccount *account in shared.allAccounts)
    {
        if (![account.email isEqualToString:accountNameInfo])
            continue;
                
        if (ar)
        {
            [account.latestEmails removeAllObjects];
            for (MCOIMAPMessage *message in ar)
                [account.latestEmails addObject:message];
        }
        
        MCOIMAPMessage *message;
        for ( int it=0;it< [account.latestEmails count ];it++)
        {
            message = (MCOIMAPMessage *)[account.latestEmails objectAtIndex:it];
            NSLog(@"%@ %@ %@",account.email, message.header.from, message.header.subject);
        }
                
    }
}

- (void) updateMailCount:(NSNotification *) notification
{
    NSLog(@"update mail count in appdelegate");
    
}



@end
