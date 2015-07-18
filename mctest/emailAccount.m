//
//  emailAccount.m
//  mctest
//
//  Created by Stéphane QUERAUD on 18/07/2015.
//  Copyright (c) 2015 Stéphane QUERAUD. All rights reserved.
//
//

#import "emailAccount.h"

@implementation emailAccount
@synthesize name,email,latestEmails,canConnect,session;

- (id) init
{
    self = [super init];
    if (self)
    {
        name = [[NSString alloc] init];
        email = [[NSString alloc] init];
      
        session = nil;
    
        latestEmails = [[NSMutableArray alloc] init];
        canConnect = true;
        
    }
    return self;
}



@end
