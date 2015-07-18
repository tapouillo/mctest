//
//  sharedGNP.h
//  mctest
//
//  Created by Stéphane QUERAUD on 18/07/2015.
//  Copyright (c) 2015 Stéphane QUERAUD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "emailAccount.h"

@interface sharedGNP : NSObject
{
    
}


@property (strong,nonatomic) NSMutableArray *allAccounts;
@property (strong,nonatomic) NSTimer *timer;
@property (readwrite) int checkEveryMinutes;
@property (readwrite) BOOL canConnectSession;


+ (sharedGNP *) sharedInstance;
- (void) initAll;
- (BOOL) initIMAPSession:(emailAccount *)account;
- (void) connectSession;
- (void) initPrefs;
- (void) stopTimer;
- (void)refreshTimer:(NSNotification*)notification;

@end