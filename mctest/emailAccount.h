//
//  emailAccount.h
//  mctest
//
//  Created by Stéphane QUERAUD on 18/07/2015.
//  Copyright (c) 2015 Stéphane QUERAUD. All rights reserved.
//

//
//  sharedGNP.h
//  Gmail Notifier Pro
//
//  Created by Stéphane QUERAUD on 30/03/2014.
//  Copyright (c) 2014 Stéphane QUERAUD. All rights reserved.
//
//
//  emailAccount.h
//  Gmail Notifier Pro
//
//  Created by Stéphane QUERAUD on 30/03/2014.
//  Copyright (c) 2014 Stéphane QUERAUD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "GTMOAuth2Authentication.h"

@interface emailAccount : NSObject
{
   
    
}


@property (strong,nonatomic)  NSString *name;
@property (strong,nonatomic)  NSString *email;

@property (strong,nonatomic)  GTMOAuth2Authentication *authSession;
@property (strong,nonatomic)  MCOIMAPSession *session;

@property (strong,nonatomic)  NSMutableArray *latestEmails;

@property (readwrite) BOOL canConnect;



@end
