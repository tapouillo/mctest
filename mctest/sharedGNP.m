//
//  sharedGNP.m
//  mctest
//
//  Created by Stéphane QUERAUD on 18/07/2015.
//  Copyright (c) 2015 Stéphane QUERAUD. All rights reserved.
//


#import "sharedGNP.h"
#import "emailAccount.h"
#import "GTMOAuth2WindowController.h"



#define kid1 @"client id"
#define ksec @"client secret"


static sharedGNP *sharedInstance = nil;
static dispatch_queue_t serialQueue;

@implementation sharedGNP

@synthesize allAccounts;
@synthesize checkEveryMinutes;
@synthesize timer;
@synthesize canConnectSession;


- (id)init
{
    self =  [super init];
    if (self)
    {
        checkEveryMinutes = 1;
        
        canConnectSession = true;
        allAccounts = nil;
        
        
    }
    return self;
}

- (void) initAll
{
   
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"newMailCount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMailCount:) name:@"newMailCount" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTimer" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTimer:) name:@"refreshTimer" object:nil];
    
  
    [self initPrefs];
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf refreshTimer:nil];
        
});
    
    
    // canConnectSession = true;
    // [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(connectSession) userInfo:nil repeats:NO];
    
}

-(void)refreshTimer:(NSNotification*)notification
{
   
    if (timer)
    {
        
        [timer invalidate];
        timer = nil;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval: checkEveryMinutes*60
                                             target: self
                                           selector:@selector(connectSessionTimer:)
                                           userInfo: nil repeats:YES];
   
    [self connectSession];
}

-(void)stopTimer
{
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
    
}
-(void)connectSessionTimer:(NSTimer *)t
{
    [self connectSession];
}

+(sharedGNP *)sharedInstance {
    static dispatch_once_t pred;
    static sharedGNP *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[sharedGNP alloc] init];
    });
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceQueue;
    
    dispatch_once(&onceQueue, ^{
        serialQueue = dispatch_queue_create("com.sovapps.gmailnotifier.SerialQueueGNP", NULL);
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
        }
    });
    
    return sharedInstance;
}

- (void) updateMailCount:(NSNotification*)notification
{
    if ([allAccounts count] > 0)
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"newTotalMailCount" object:nil];
         NSLog(@"update mail count");
    }
}


-(void) loadAccounts
{
    emailAccount *account;
    
    account = [[emailAccount alloc] init];
    account.name = @"name1";
    account.email = @"email1@gmail.com";
    [allAccounts addObject:account];
    
    account = [[emailAccount alloc] init];
    account.name = @"name1";
    account.email = @"email2@gmail.com";
    [allAccounts addObject:account];

    account = [[emailAccount alloc] init];
    account.name = @"name1";
    account.email = @"email2@gmail.com";
    [allAccounts addObject:account];
    
}

- (void) initPrefs
{
    
    allAccounts = nil;
    allAccounts = [[NSMutableArray alloc] init];
    
    [self loadAccounts];
    
    
    //-------- create session --------------------
    if ([allAccounts count] > 0)
    {
        for (emailAccount *account in allAccounts)
        {
            //[GTMOAuth2WindowController removeAuthFromKeychainForName:account.email];
            [self initIMAPSession:account];
        }
    }
    //---------------------------------------------
    
}

- (void) getMailCount:(emailAccount *)account
{
  
    
    BOOL needsInit = [self initIMAPSession:account];
    int delay = 0;
    if (!needsInit)
        delay = 5;
    
    __weak typeof(self)weakSelf = self;
    __weak typeof(emailAccount *)weakAccount = account;
    
   
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), [account.session dispatchQueue], ^{
        
        
        MCOIMAPFolderStatusOperation *statusOperation = [weakAccount.session folderStatusOperation:@"INBOX"];
        
    
        [statusOperation start:^(NSError *error, MCOIMAPFolderStatus *status)
         {
            
             if (error)
             {
                 NSString *errorMessage = [NSString stringWithFormat:@"%@",[error localizedDescription]];
                 NSLog(@"error get mail count: %@",errorMessage);
             }
             else
             {
                  NSLog(@"count %i", status.messageCount);
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"newMailCount" object:nil];
                 
             }
         }];
        
        
    });
}


- (void)auth:(GTMOAuth2Authentication *)auth finishedRefreshWithFetcher:(GTMHTTPFetcher *)fetcher error:(NSError *)error
{
    [self windowController:nil finishedWithAuth:auth error:error];
}

- (void)windowController:(GTMOAuth2WindowController *)viewController finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
    
    if (error != nil)
    {
        // Authentication failed
        for (emailAccount *account in allAccounts)
        {
            account.canConnect = YES;
        }
        return;
    }
    
    NSString * email = [auth userEmail];
    NSString * accessToken = [auth accessToken];
    
    for (emailAccount *account in allAccounts)
    {
        if ([account.email isEqualToString:email])
        {
            
            account.authSession = auth;
          
            account.session = [[MCOIMAPSession alloc] init];
            [account.session setAuthType:MCOAuthTypeXOAuth2];
            [account.session setOAuth2Token:accessToken];
            [account.session setUsername:account.email];
            [account.session setHostname:@"imap.gmail.com"];
            [account.session setPort:993];
            [account.session setConnectionType:MCOConnectionTypeTLS];
           
            /*
            account.smtpSession = [[MCOSMTPSession alloc] init];
            [account.smtpSession setAuthType:MCOAuthTypeXOAuth2];
            [account.smtpSession setOAuth2Token:accessToken];
            [account.smtpSession setHostname:@"smtp.gmail.com"];
            [account.smtpSession setPort:465];
            [account.smtpSession setUsername:account.email];
            [account.smtpSession setConnectionType:MCOConnectionTypeTLS];
            */
            
            account.canConnect = YES;
            
          
            
            [[account.session fetchAllFoldersOperation]start:^(NSError * error, NSArray * /* MCOIMAPFolder */ folders) {
                if (!error)
                {
                    for (MCOIMAPFolder *fdr in folders)
                    {
                        //NSLog(@"%@ %d", fdr.path, (int)fdr.flags);
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"newAccountList" object:nil];
                }
                
            }];
            
        }
    }
    
    
    
}





- (BOOL) initIMAPSession:(emailAccount *)account
{
    
    if ( account.canConnect == false) return false;
    
    
    NSString *scope = @"https://www.google.com/m8/feeds/ https://mail.google.com/ https://www.googleapis.com/auth/userinfo.profile";
    
    if (account.authSession == nil)
    {
       
        account.canConnect = NO;
        
        account.authSession = [GTMOAuth2WindowController authForGoogleFromKeychainForName:account.email
                                                                                 clientID:kid1
                                                                             clientSecret:ksec];
        
    }
    
    if ([account.authSession refreshToken] == nil)
    {
       
        account.canConnect = NO;
        
      
        GTMOAuth2WindowController *windowController =
        [[GTMOAuth2WindowController alloc] initWithScope:scope
                                                clientID:kid1
                                            clientSecret:ksec
                                        keychainItemName:account.email
                                          resourceBundle:[NSBundle bundleForClass:[GTMOAuth2WindowController class]]];
        GTMOAuth2SignIn *signIn = windowController.signIn;
        signIn.additionalAuthorizationParameters = @{@"login_hint" : account.email};
        
       
        [windowController signInSheetModalForWindow:nil
                                           delegate:self
                                   finishedSelector:@selector(windowController:finishedWithAuth:error:)];
        
        return FALSE;
    }
    else if ([[account.authSession expirationDate] earlierDate:[NSDate date]] == [account.authSession expirationDate])
    {
      
        account.canConnect = NO;
        
        [account.authSession beginTokenFetchWithDelegate:self
                                       didFinishSelector:@selector(auth:finishedRefreshWithFetcher:error:)];
        return FALSE;
    }
    
    return TRUE;
    
}
- (void) getLastEmails:(emailAccount *)account
{
    
    int maxEmails = 10;
    
    
    BOOL needsInit = [self initIMAPSession:account];
    int delay = 0;
    if (!needsInit)
        delay = 5;
    
  
    
    __weak typeof(emailAccount *)weakaccount = account;
    __weak typeof(self)weakSelf = self;
    
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), [weakaccount.session dispatchQueue], ^{
        
           
        MCOIMAPFolderInfoOperation *infoOperation = [weakaccount.session folderInfoOperation:@"INBOX"];
        [infoOperation start:^(NSError *error, MCOIMAPFolderInfo *info)
         {
             if (!error)
             {
                 uint64_t location = MAX([info messageCount] - maxEmails + 1, 1);
                 uint64_t size = [info messageCount] < maxEmails ? [info messageCount] - 1 : maxEmails - 1;
                 MCOIndexSet *numbers = [MCOIndexSet indexSetWithRange:MCORangeMake(location, size)];
                 
                
                 [weakSelf getLastEmailsStep2:weakaccount withNumber:numbers];
             }
             else
             {
                 
             }
         }];
        
    });
}
- (void) getLastEmailsStep2:(emailAccount *)account withNumber:(MCOIndexSet *)numbers
{
    
    
    MCOIMAPMessagesRequestKind kind =  MCOIMAPMessagesRequestKindUid |
    MCOIMAPMessagesRequestKindFullHeaders |
    MCOIMAPMessagesRequestKindFlags |
    MCOIMAPMessagesRequestKindHeaders |
    MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindGmailMessageID | MCOIMAPMessagesRequestKindStructure;
    
    __weak typeof(emailAccount *)weakaccount = account;
    __weak typeof(self)weakSelf = self;
    
     MCOIMAPFetchMessagesOperation *fetchOperation = [weakaccount.session fetchMessagesByNumberOperationWithFolder:@"INBOX" requestKind:kind numbers:numbers];
    
    [fetchOperation start:^(NSError * error, NSArray * fetchedMessages, MCOIndexSet * vanishedMessages)
     {
         
         if(error)
         {
            
          
         }
         else
         {
             
             NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
             [userInfo setObject:fetchedMessages forKey:@"fetchedMessage"];
             [userInfo setObject:weakaccount.email forKey:@"accountEmail"];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"newEmails" object:nil userInfo:userInfo];
             
             fetchedMessages = nil;
             userInfo = nil;
             
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"updateCheckNow" object:nil];
         
     }
     ];
}

-(void) canConnect
{
    canConnectSession = true;
}

- (void) connectSession
{
  
    if (canConnectSession)
    {
        canConnectSession = false;
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(canConnect) userInfo:nil repeats:NO];
        
        
        if ([allAccounts count] > 0)
        {
            for (emailAccount *account in allAccounts)
            {
                NSLog(@"connectSession for %@",account.email);
                [self getMailCount:account];
                [self getLastEmails:account];
                
            }
        }
        
    }
    else
    {
       
    }
}

@end
