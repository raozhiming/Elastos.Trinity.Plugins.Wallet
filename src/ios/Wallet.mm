/*
 * Copyright (c) 2019 Elastos Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "Wallet.h"
#import <Cordova/CDVCommandDelegate.h>
#import "WrapSwift.h"

#pragma mark - ElISubWalletCallback C++

using namespace Elastos::ElaWallet;
class ElISubWalletCallback: public ISubWalletCallback
{
public:
    ElISubWalletCallback(String &masterWalletID, String &chainID, NSMutableDictionary *commandDict);

    ~ElISubWalletCallback();

    void SendPluginResult(NSDictionary* dict);

    CDVPluginResult *successAsDict(NSDictionary* dict);
    CDVPluginResult *successAsString(NSString* str);
    CDVPluginResult *errorProcess(int code, id msg);

    void OnTransactionStatusChanged(const std::string &txid, const std::string &status, const nlohmann::json &desc, uint32_t confirms);
    void OnBalanceChanged(const std::string &asset, const std::string & balance);
    void OnBlockSyncProgress(const nlohmann::json &progressInfo);
    void OnTxPublished(const std::string &hash, const nlohmann::json &result);
    void OnAssetRegistered(const std::string &asset, const nlohmann::json &info);
    void OnConnectStatusChanged(const std::string &status);
    void OnETHSCEventHandled(const nlohmann::json &event);

private:
    NSString * mMasterWalletID;
    NSString * mSubWalletID;
    NSMutableDictionary *mCommandDict;
    NSString *keySuccess;//   = @"success";
    NSString *keyError;//     = "error";
    NSString *keyCode;//      = "code";
    NSString *keyMessage;//   = "message";
    NSString *keyException;// = "exception";
};
ElISubWalletCallback::ElISubWalletCallback(String &masterWalletID,
                                           String &chainID, NSMutableDictionary *commandDict)
{
    mMasterWalletID = [NSString stringWithCString:masterWalletID.c_str() encoding:NSUTF8StringEncoding];
    mSubWalletID = [NSString stringWithCString:chainID.c_str() encoding:NSUTF8StringEncoding];
    mCommandDict = commandDict;

    keySuccess   = @"success";
    keyError     = @"error";
    keyCode      = @"code";
    keyMessage   = @"message";
    keyException = @"exception";
}

ElISubWalletCallback::~ElISubWalletCallback()
{
}

CDVPluginResult *ElISubWalletCallback::successAsDict(NSDictionary* dict)
{
    [dict setValue:mMasterWalletID forKey:@"MasterWalletID"];
    [dict setValue:mSubWalletID forKey:@"ChainID"];

    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    return pluginResult;
}

CDVPluginResult *ElISubWalletCallback::successAsString(NSString* str)
{
    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:str];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    return pluginResult;
}

CDVPluginResult *ElISubWalletCallback::errorProcess(int code, id msg)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[NSNumber numberWithInt:code] forKey:keyCode];
    [dict setValue:msg forKey:keyMessage];

    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary: dict];
    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    return pluginResult;
}

void ElISubWalletCallback::OnTransactionStatusChanged(const std::string &txid,
                        const std::string &status, const nlohmann::json &desc, uint32_t confirms)
{
    NSLog(@" ----OnTransactionStatusChanged ----\n");
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSString *txIdStr = [NSString stringWithCString:txid.c_str() encoding:NSUTF8StringEncoding];
    NSString *statusStr = [NSString stringWithCString:status.c_str() encoding:NSUTF8StringEncoding];
    NSString *descStr = [NSString stringWithCString:desc.dump().c_str() encoding:NSUTF8StringEncoding];
    NSNumber *confirmNum = [NSNumber numberWithInt:confirms];

    [dict setValue:txIdStr forKey:@"txId"];
    [dict setValue:statusStr forKey:@"status"];
    [dict setValue:descStr forKey:@"desc"];
    [dict setValue:confirmNum forKey:@"confirms"];
    [dict setValue:@"OnTransactionStatusChanged" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::OnBlockSyncProgress(const nlohmann::json &progressInfo)
{
    NSLog(@" ----OnBlockSyncProgress ----\n");

    NSString *progressInfoString = [NSString stringWithCString:progressInfo.dump().c_str() encoding:NSUTF8StringEncoding];

    NSError *err;
    NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:[progressInfoString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    [dict setValue:@"OnBlockSyncProgress" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::OnBalanceChanged(const std::string &asset, const std::string &balance)
{
    NSLog(@" ----OnBalanceChanged ----\n");
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    NSString *assetString = [NSString stringWithCString:asset.c_str() encoding:NSUTF8StringEncoding];
    NSString *balanceString = [NSString stringWithCString:balance.c_str() encoding:NSUTF8StringEncoding];

    [dict setValue:assetString forKey:@"Asset"];
    [dict setValue:balanceString forKey:@"Balance"];
    [dict setValue:@"OnBalanceChanged" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::OnTxPublished(const std::string &hash, const nlohmann::json &result)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    NSString *hashString = [NSString stringWithCString:hash.c_str() encoding:NSUTF8StringEncoding];
    NSString *resultString = [NSString stringWithCString:result.dump().c_str() encoding:NSUTF8StringEncoding];

    [dict setValue:hashString forKey:@"hash"];
    [dict setValue:resultString forKey:@"result"];
    [dict setValue:@"OnTxPublished" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::OnAssetRegistered(const std::string &asset, const nlohmann::json &info)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    NSString *assetString = [NSString stringWithCString:asset.c_str() encoding:NSUTF8StringEncoding];
    NSString *infoString = [NSString stringWithCString:info.dump().c_str() encoding:NSUTF8StringEncoding];

    [dict setValue:assetString forKey:@"asset"];
    [dict setValue:infoString forKey:@"info"];
    [dict setValue:@"OnAssetRegistered" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::OnConnectStatusChanged(const std::string &status)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSString *statusString = [NSString stringWithCString:status.c_str() encoding:NSUTF8StringEncoding];

    [dict setValue:statusString forKey:@"status"];
    [dict setValue:@"OnConnectStatusChanged" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::OnETHSCEventHandled(const nlohmann::json &event)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSString *eventString = [NSString stringWithCString:event.dump().c_str() encoding:NSUTF8StringEncoding];

    [dict setValue:eventString forKey:@"event"];
    [dict setValue:@"OnETHSCEventHandled" forKey:@"Action"];

    SendPluginResult(dict);
}

void ElISubWalletCallback::SendPluginResult(NSDictionary* dict)
{
    CDVPluginResult* pluginResult = nil;
    pluginResult = successAsDict(dict);

    for (id key in subwalletListenerMDict) {
        NSMutableDictionary *commandDict = [subwalletListenerMDict objectForKey:key];
        CDVInvokedUrlCommand* command = [commandDict objectForKey:@"command"];
        id <CDVCommandDelegate> commandDelegate = [commandDict objectForKey:@"commandDelegate"];
        [commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

#pragma mark - Wallet

@interface Wallet ()
{
    //    ELIIdManagerCallback *iidCallback;
}

@end


@implementation Wallet

#pragma mark -
- (IMasterWallet *)getIMasterWallet:(String)masterWalletID
{
    if (mMasterWalletManager == nil) {
        return nil;
    }
    return mMasterWalletManager->GetMasterWallet(masterWalletID);
}

- (ISubWallet *)getSubWallet:(String)masterWalletID :(String)chainID
{
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        return nil;
    }
    ISubWalletVector subWalletList = masterWallet->GetAllSubWallets();
    for (int i = 0; i < subWalletList.size(); i++) {
        ISubWallet *iSubWallet = subWalletList[i];
        NSString *getChainIDString = [self stringWithCString:iSubWallet->GetChainID()];
        NSString *chainIDString = [self stringWithCString:chainID];

        if ([chainIDString isEqualToString:getChainIDString]) {
            return iSubWallet;
        }
    }
    return nil;
}

#pragma mark -

- (NSString *)getBasicInfo:(IMasterWallet *)masterWallet
{
    Json json = masterWallet->GetBasicInfo();
    NSString *jsonString = [self stringWithCString:json.dump()];
    return jsonString;
}

- (NSString *)formatWalletName:(String)stdStr
{
    NSString *string = [self stringWithCString:stdStr];
    NSString *str = [NSString stringWithFormat:@"(%@)", string];
    return str;
}
- (NSString *)formatWalletNameWithString:(String)stdStr other:(String)other
{
    NSString *string = [self stringWithCString:stdStr];
    NSString *otherString = [self stringWithCString:other];
    NSString *str = [NSString stringWithFormat:@"(%@:%@)", string, otherString];
    return str;
}

- (void)errCodeInvalidArg:(CDVInvokedUrlCommand *)command code:(int)code idx:(int)idx
{
    NSString *msg = [NSString stringWithFormat:@"%d %@", idx, @" parameters are expected"];
    return [self errorProcess:command code:code msg:msg];
}

- (void)successAsDict:(CDVInvokedUrlCommand *)command  msg:(NSDictionary*) dict
{
    CDVPluginResult*  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)successAsString:(CDVInvokedUrlCommand *)command  msg:(NSString*) msg
{
    CDVPluginResult*  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)errorProcess:(CDVInvokedUrlCommand *)command  code : (int) code msg:(id) msg
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[NSNumber numberWithInt:code] forKey:keyCode];
    [dict setValue:msg forKey:keyMessage];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dict];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)exceptionProcess:(CDVInvokedUrlCommand *)command  string:(String) exceptionString
{
    NSString *errString=[self stringWithCString:exceptionString];
    NSDictionary *dic=  [self dictionaryWithJsonString:errString];
    [self errorProcess:command code:[dic[@"Code"] intValue] msg:dic[@"Message"]];
}

- (NSDictionary *)parseOneParam:(NSString *)key value:(NSString *)value
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:value forKey:key];
    return dict;
}

- (NSString *)dictToJSONString:(NSDictionary *)dict
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                        options:kNilOptions
                                        error:nil];
    if (data == nil) {
        return nil;
    }

    NSString *string = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
    return string;
}

- (NSString *)arrayToJSONString:(NSArray *)array
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:array
                                        options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments
                                        error:nil];
    if (data == nil) {
        return nil;
    }

    NSString *string = [[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding];
    return string;
}
#pragma mark - String Json NSString

- (Json)jsonWithString:(NSString *)string
{
    String std = [self cstringWithString:string];
    Json json = Json::parse(std);
    return json;
}

- (Json)jsonWithDict:(NSDictionary *)dict
{
    NSString *string = [self dictToJSONString:dict];
    String std = [self cstringWithString:string];
    Json json = Json::parse(std);
    return json;
}

- (NSString *)stringWithJson:(Json)json
{
    return [self stringWithCString:json.dump()];
}
//String 转 NSString
- (NSString *)stringWithCString:(String)string
{
    //    NSString *str = [NSString stringWithCString:string.c_str() encoding:[NSString defaultCStringEncoding]];
    NSString *str = [NSString stringWithCString:string.c_str() encoding:NSUTF8StringEncoding];
    //    str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    //    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    NSString *beginStr = [str substringWithRange:NSMakeRange(0, 1)];

    NSString *result = str;
    if([beginStr isEqualToString:@"\""])
    {
        result = [str substringWithRange:NSMakeRange(1, str.length - 1)];
        //        result = [str stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    NSString *endStr = [result substringWithRange:NSMakeRange(result.length - 1, 1)];
    if([endStr isEqualToString:@"\""])
    {
        //        [str stringByReplacingCharactersInRange:NSMakeRange(str.length - 1, 1) withString:@""];
        result = [result substringWithRange:NSMakeRange(0, result.length - 1)];
    }
    return result;
}

- (String)cstringWithString:(NSString *)string
{
    String  str = [string UTF8String];
    return str;
}

-(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [[jsonString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\\r\\n"] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                            options:NSJSONReadingMutableContainers
                                            error:&err];
    if(err) {
        return nil;
    }
    return dic;
}

#pragma mark - plugin

- (void)applicationEnterBackground
{
    // if (mMasterWalletManager != nil) {
    //     mMasterWalletManager->SaveConfigs();
    // }
}
- (void)applicationBecomeActive
{

}

- (void)pluginInitialize
{
    // app启动或者app从后台进入前台都会调用这个方法
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    // app从后台进入前台都会调用这个方法
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    // 添加检测app进入后台的观察者
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];

    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApplicationWillTerminateNotification) name: UIApplicationWillTerminateNotification object:nil];


    //    ISubWalletVector = new  ISubWalletVector();
    //    ISubWalletArray = [[NSMutableArray alloc] init];
    //    ISubWalletCallBackArray = [[NSMutableArray alloc] init];
    //
    TAG = @"Wallet";

    walletRefCount++;//delete mMasterWalletManager in dispose?

    if (nil != mMasterWalletManager) return;

    mRootPath = NULL;

    keySuccess   = @"success";
    keyError     = @"error";
    keyCode      = @"code";
    keyMessage   = @"message";
    keyException = @"exception";

    errCodeParseJsonInAction          = 10000;
    errCodeInvalidArg                 = 10001;
    errCodeInvalidMasterWallet        = 10002;
    errCodeInvalidSubWallet           = 10003;
    errCodeCreateMasterWallet         = 10004;
    errCodeCreateSubWallet            = 10005;
    errCodeRecoverSubWallet           = 10006;
    errCodeInvalidMasterWalletManager = 10007;
    errCodeImportFromKeyStore         = 10008;
    errCodeImportFromMnemonic         = 10009;
    errCodeSubWalletInstance          = 10010;
    errCodeActionNotFound             = 10013;
    errCodeGetAllMasterWallets        = 10014;

    errCodeWalletException            = 20000;

    // NSString* rootPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/spv"];
    NSString* rootPath = [[self getDataPath] stringByAppendingString:@"spv"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:rootPath]) {
        [fm createDirectoryAtPath:rootPath withIntermediateDirectories:true attributes:NULL error:NULL];
    }

    NSString* dataPath = [rootPath stringByAppendingString:@"/data"];
    if (![fm fileExistsAtPath:dataPath]) {
        [fm createDirectoryAtPath:dataPath withIntermediateDirectories:true attributes:NULL error:NULL];
    }
    NSString* netType = [WrapSwift getWalletNetworkType];
    NSString* config = [WrapSwift getWalletNetworkConfig];

    try {
        mMasterWalletManager = new MasterWalletManager([rootPath UTF8String], [netType UTF8String],
                [config UTF8String], [dataPath UTF8String]);
    } catch (const std:: exception & e ) {
        NSString *errString=[self stringWithCString:e.what()];
        NSLog(@"new MasterWalletManager error: %@", errString);
    }

    [self addWalletListener];

    [super pluginInitialize];
}

- (void)coolMethod:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];

    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)print:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *pluginResult = nil;
    NSString *text = [command.arguments objectAtIndex:0];

    if(!text || ![text isEqualToString:@""]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self parseOneParam:@"text" value:text]];
    }
    else {
        NSString *error = @"Text not can be null";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)addWalletListener
{
    try {
        IMasterWalletVector masterWallets = mMasterWalletManager->GetAllMasterWallets();

        for (int i = 0; i < masterWallets.size(); i++) {
            IMasterWallet *masterWallet = masterWallets[i];
            String masterWalletID = masterWallet->GetID();

            ISubWalletVector subWallets = masterWallet->GetAllSubWallets();
            for (int j = 0; j < subWallets.size(); j++) {
                String chainID = subWallets[j]->GetChainID();
                [self addSubWalletListener:masterWalletID chainID:chainID];
            }
        }
    } catch (const std:: exception &e) {
        NSLog(@"addWalletListener error: %s", e.what());
    }
}

- (void)addSubWalletListener:(String)masterWalletID chainID:(String)chainID
{
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        NSLog(@"addSubWalletListener error: %@", msg);
        return;
    }

    ElISubWalletCallback *subCallback =  new ElISubWalletCallback(masterWalletID, chainID, subwalletListenerMDict);
    subWallet->AddCallback(subCallback);
}

- (void)getAllMasterWallets:(CDVInvokedUrlCommand *)command
{
    try {
        IMasterWalletVector vector = mMasterWalletManager->GetAllMasterWallets();
        NSMutableArray *masterWalletListJson = [[NSMutableArray alloc] init];
        for (int i = 0; i < vector.size(); i++) {
            IMasterWallet *iMasterWallet = vector[i];
            String idStr = iMasterWallet->GetID();
            NSString *str = [self stringWithCString:idStr];
            [masterWalletListJson addObject:str];
        }
        NSString *jsonString = [self arrayToJSONString:masterWalletListJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createMasterWallet:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *array = command.arguments;

    String masterWalletID = [self cstringWithString:[array objectAtIndex:idx++]];
    String mnemonic       = [self cstringWithString:[array objectAtIndex:idx++]];
    String phrasePassword = [self cstringWithString:[array objectAtIndex:idx++]];
    String payPassword    = [self cstringWithString:[array objectAtIndex:idx++]];
    Boolean singleAddress = [[array objectAtIndex:idx++] boolValue];

    NSArray *args = command.arguments;
    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }

    try {
        IMasterWallet *masterWallet = mMasterWalletManager->CreateMasterWallet(
                masterWalletID, mnemonic, phrasePassword, payPassword, singleAddress);

        if (masterWallet == NULL) {
            NSString *msg = [NSString stringWithFormat:@"CreateMasterWallet %@", [self formatWalletName:masterWalletID]];
            return [self errorProcess:command code:errCodeCreateMasterWallet msg:msg];
        }

        NSString *jsonString = [self getBasicInfo:masterWallet];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)generateMnemonic:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    NSString *language = args[idx++];
    //
    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    if (mMasterWalletManager == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@", @"Master wallet manager has not initialize"];
        return [self errorProcess:command code:errCodeInvalidMasterWalletManager msg:msg];
    }

    try {
        String mnemonic = mMasterWalletManager->GenerateMnemonic([self cstringWithString:language]);
        NSString *mnemonicString = [self stringWithCString:mnemonic];

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:mnemonicString];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createSubWallet:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        ISubWallet *subWallet = masterWallet->CreateSubWallet(chainID);
        if (subWallet == nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ %@", @"CreateSubWallet", [self formatWalletNameWithString:masterWalletID other:chainID]];
            return [self errorProcess:command code:errCodeCreateSubWallet msg:msg];
        }
        Json json = subWallet->GetBasicInfo();
        NSString *jsonString = [self stringWithCString:json.dump()];

        [self addSubWalletListener:masterWalletID chainID:chainID];

        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }

}
- (void)getAllSubWallets:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }

    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }
    NSMutableArray *subWalletJsonArray = [[NSMutableArray alloc] init];

    try {
        ISubWalletVector subWalletList = masterWallet->GetAllSubWallets();
        for (int i = 0; i < subWalletList.size(); i++) {
            ISubWallet *iSubWallet = subWalletList[i];
            String chainId = iSubWallet->GetChainID();
            NSString *chainIdString = [self stringWithCString:chainId];
            [subWalletJsonArray addObject:chainIdString];
        }
        NSString *msg = [self arrayToJSONString:subWalletJsonArray];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)registerWalletListener:(CDVInvokedUrlCommand *)command
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:command forKey:@"command"];
    [dict setValue:self.commandDelegate forKey:@"commandDelegate"];

    NSString *key = [NSString stringWithFormat:@"(%@:%@)", [self did], [self getModeId]];
    [subwalletListenerMDict setValue:dict forKey:key];
}

- (void)removeWalletListener:(CDVInvokedUrlCommand *)command
{
    NSString *key = [NSString stringWithFormat:@"(%@:%@)", [self did], [self getModeId]];
    [subwalletListenerMDict removeObjectForKey:key];
    return [self successAsString:command msg:@"remove listener"];
}

- (void)getBalance:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        String balance = subWallet->GetBalance();
        NSString *balanceStr = [self stringWithCString:balance];

        return [self successAsString:command msg:balanceStr];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getBalanceInfo:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = subWallet->GetBalanceInfo();
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getSupportedChains:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        StringVector stringVec = masterWallet->GetSupportedChains();
        NSMutableArray *stringArray = [[NSMutableArray alloc] init];
        for(int i = 0; i < stringVec.size(); i++) {
            String string = stringVec[i];
            NSString *sstring = [self stringWithCString:string];
            [stringArray addObject:sstring];
        }

        CDVPluginResult*  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:stringArray];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getMasterWalletBasicInfo:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }
    NSString *jsonString = [self getBasicInfo:masterWallet];
    return [self successAsString:command msg:jsonString];
}

- (void)getAllTransaction:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    int    start          = [args[idx++] intValue];
    int    count          = [args[idx++] intValue];
    String addressOrTxId  = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID : chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = subWallet->GetAllTransaction(start, count, addressOrTxId);
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getLastBlockInfo:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID : chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = subWallet->GetLastBlockInfo();
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createAddress:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        String address = subWallet->CreateAddress();
        NSString *jsonString = [self stringWithCString:address];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getGenesisAddress:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    ISidechainSubWallet *sidechainSubWallet = dynamic_cast<ISidechainSubWallet *>(subWallet);
    if(sidechainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of ISidechainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        String address = sidechainSubWallet->GetGenesisAddress();
        NSString *jsonString = [self stringWithCString:address];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)exportWalletWithKeystore:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String backupPassword = [self cstringWithString:args[idx++]];
    String payPassword = [self cstringWithString:args[idx++]];
    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        Json json = masterWallet->ExportKeystore(backupPassword, payPassword);
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)exportWalletWithMnemonic:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String backupPassword = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        Json json = masterWallet->ExportMnemonic(backupPassword);
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)verifyPassPhrase:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String passPhrase     = [self cstringWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        masterWallet->VerifyPassPhrase(passPhrase, payPassword);
        return [self successAsString:command msg:@"Verify passPhrase OK"];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)verifyPayPassword:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String payPassword = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        masterWallet->VerifyPayPassword(payPassword);
        return [self successAsString:command msg:@"Verify pay password OK"];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)changePassword:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String oldPassword = [self cstringWithString:args[idx++]];
    String newPassword = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        masterWallet->ChangePassword(oldPassword, newPassword);
        return [self successAsString:command msg:@"Change password OK"];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getPubKeyInfo:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    try {
        masterWallet->GetPubKeyInfo();
        return [self successAsString:command msg:@"Get pubKey info OK"];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)importWalletWithKeystore:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    Json keystoreContent    = [self jsonWithString:args[idx++]];
    String backupPassword   = [self cstringWithString:args[idx++]];
    String payPassword      = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }

    try {
        IMasterWallet *masterWallet = mMasterWalletManager->ImportWalletWithKeystore(
                masterWalletID, keystoreContent, backupPassword, payPassword);
        if (masterWallet == nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"Import", [self formatWalletName:masterWalletID], @"with keystore"];
            return [self errorProcess:command code:errCodeImportFromKeyStore msg:msg];
        }
        NSString *jsonString = [self getBasicInfo:masterWallet];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)importWalletWithMnemonic:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String mnemonic       = [self cstringWithString:args[idx++]];
    String phrasePassword = [self cstringWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];
    Boolean singleAddress =  [args[idx++] boolValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }

    try {
        IMasterWallet *masterWallet = mMasterWalletManager->ImportWalletWithMnemonic(
                masterWalletID, mnemonic, phrasePassword, payPassword, singleAddress);
        if (masterWallet == nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"ImportWalletWithMnemonic", [self formatWalletName:masterWalletID], @"with mnemonic"];
            return [self errorProcess:command code:errCodeImportFromMnemonic msg:msg];
        }
        NSString *jsonString = [self getBasicInfo:masterWallet];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createMultiSignMasterWalletWithMnemonic:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String mnemonic       = [self cstringWithString:args[idx++]];
    String phrasePassword = [self cstringWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];
    String str            = [self cstringWithString:args[idx++]];
    Json publicKeys       = Json::parse(str);
    int m                 = [args[idx++] intValue];
    long timestamp        = [args[idx++] longValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    if (mMasterWalletManager == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@", @"Master wallet manager has not initialize"];
        return [self errorProcess:command code:errCodeInvalidMasterWalletManager msg:msg];
    }

    try {
        IMasterWallet *masterWallet = mMasterWalletManager->CreateMultiSignMasterWallet(
                masterWalletID, mnemonic, phrasePassword, payPassword, publicKeys, m, timestamp);
        if (masterWallet == nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"Create multi sign", [self formatWalletName:masterWalletID], @"with mnemonic"];
            return [self errorProcess:command code:errCodeCreateMasterWallet msg:msg];
        }
        NSString *jsonString = [self getBasicInfo:masterWallet];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createMultiSignMasterWallet:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String str = [self cstringWithString:args[idx++]];
    Json publicKeys = Json::parse(str);
    int m = [args[idx++] intValue];
    long timestamp = [args[idx++] longValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    if (mMasterWalletManager == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@", @"Master wallet manager has not initialize"];
        return [self errorProcess:command code:errCodeInvalidMasterWalletManager msg:msg];
    }

    try {
        IMasterWallet *masterWallet = mMasterWalletManager->CreateMultiSignMasterWallet(
                masterWalletID, publicKeys, m, timestamp);
        if (masterWallet == nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Create multi sign", [self formatWalletName:masterWalletID]];
            return [self errorProcess:command code:errCodeCreateMasterWallet msg:msg];
        }
        NSString *jsonString = [self getBasicInfo:masterWallet];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createMultiSignMasterWalletWithPrivKey:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String privKey        = [self cstringWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];
    String str            = [self cstringWithString:args[idx++]];
    Json publicKeys       = Json::parse(str);
    int m                 = [args[idx++] intValue];
    long timestamp        = [args[idx++] longValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    if (mMasterWalletManager == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@", @"Master wallet manager has not initialize"];
        return [self errorProcess:command code:errCodeInvalidMasterWalletManager msg:msg];
    }

    try {
        IMasterWallet *masterWallet = mMasterWalletManager->CreateMultiSignMasterWallet(
                masterWalletID, privKey, payPassword, publicKeys, m, timestamp);
        if (masterWallet == nil) {
            NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"Create multi sign", [self formatWalletName:masterWalletID], @"with private key"];
            return [self errorProcess:command code:errCodeCreateMasterWallet msg:msg];
        }
        NSString *jsonString = [self getBasicInfo:masterWallet];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getAllAddress:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    int start             = [args[idx++] intValue];
    int count             = [args[idx++] intValue];
    Boolean internal      = [args[idx++] boolValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = subWallet->GetAllAddress(start, count, internal);
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getAllPublicKeys:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    int start             = [args[idx++] intValue];
    int count             = [args[idx++] intValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = subWallet->GetAllPublicKeys(start, count);
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)isAddressValid:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String addr             = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    Boolean valid = masterWallet->IsAddressValid(addr);
    CDVPluginResult*  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:valid];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)createDepositTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID    = [self cstringWithString:args[idx++]];
    String chainID           = [self cstringWithString:args[idx++]];
    String fromAddress       = [self cstringWithString:args[idx++]];
    String lockedAddress     = [self cstringWithString:args[idx++]];
    String amount            = [self cstringWithString:args[idx++]];
    String sideChainAddress  = [self cstringWithString:args[idx++]];
    String memo              = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = mainchainSubWallet->CreateDepositTransaction(fromAddress, lockedAddress, amount, sideChainAddress, memo);
        NSString *jsonString = [self stringWithCString:json.dump()];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)destroyWallet:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }

    ISubWalletVector subWallets = masterWallet->GetAllSubWallets();
    for (int i = 0; i < subWallets.size(); i++) {
        subWallets[i]->SyncStop();
        subWallets[i]->RemoveCallback();
        masterWallet->DestroyWallet(subWallets[i]->GetChainID());
    }

    if (mMasterWalletManager == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@", @"Master wallet manager has not initialize"];
        return [self errorProcess:command code:errCodeInvalidMasterWalletManager msg:msg];
    }

    try {
        mMasterWalletManager->DestroyWallet(masterWalletID);
        NSString *msg = [NSString stringWithFormat:@"Destroy %@ OK", [self formatWalletName:masterWalletID]];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    String toAddress      = [self cstringWithString:args[idx++]];
    String amount         = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = subWallet->CreateTransaction(fromAddress, toAddress, amount, memo);
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getAllUTXOs:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    int start             = [args[idx++] intValue];
    int count             = [args[idx++] intValue];
    String address        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json result = subWallet->GetAllUTXOs(start, count, address);
        NSString *msg = [self stringWithJson:result];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createConsolidateTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json result = subWallet->CreateConsolidateTransaction(memo);
        NSString *msg = [self stringWithJson:result];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)signTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    Json rawTransaction   = [self jsonWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json result = subWallet->SignTransaction(rawTransaction, payPassword);
        NSString *msg = [self stringWithJson:result];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)publishTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    Json rawTxJson        =  [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json result = subWallet->PublishTransaction(rawTxJson);
        NSString *msg = [self stringWithJson:result];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getTransactionSignedInfo:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    Json rawTxJson        = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }

    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json resultJson = subWallet->GetTransactionSignedInfo(rawTxJson);
        NSString *jsonString = [self stringWithJson:resultJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createIdTransaction:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithDict:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IIDChainSubWallet *idchainSubWallet = dynamic_cast<IIDChainSubWallet *>(subWallet);
    if(idchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"is not instance of IIDChainSubWallet", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = idchainSubWallet->CreateIDTransaction(payloadJson, memo);
        NSString *msg = [self stringWithJson:json];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createWithdrawTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    String amount         = [self cstringWithString:args[idx++]];
    String mainchainAddress  = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    ISidechainSubWallet *sidechainSubWallet = dynamic_cast<ISidechainSubWallet *>(subWallet);
    if(sidechainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of ISidechainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = sidechainSubWallet->CreateWithdrawTransaction(fromAddress, amount, mainchainAddress, memo);
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getMasterWallet:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }
    NSString *jsonString = [self getBasicInfo:masterWallet];
    return [self successAsString:command msg:jsonString];
}

- (void)destroySubWallet:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;
    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IMasterWallet *masterWallet = [self getIMasterWallet:masterWalletID];
    if (masterWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletName:masterWalletID]];
        return [self errorProcess:command code:errCodeInvalidMasterWallet msg:msg];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        subWallet->SyncStop();
        subWallet->RemoveCallback();
        masterWallet->DestroyWallet(chainID);

        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Destroy", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self successAsString:command msg:msg];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getVersion:(CDVInvokedUrlCommand *)command
{
    if (mMasterWalletManager == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@", @"Master wallet manager has not initialize"];
        return [self errorProcess:command code:errCodeInvalidMasterWalletManager msg:msg];
    }
    String version = mMasterWalletManager->GetVersion();
    NSString *msg = [self stringWithCString:version];
    return [self successAsString:command msg:msg];
}

- (void)generateProducerPayload:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;
    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String publicKey      = [self cstringWithString:args[idx++]];
    String nodePublicKey  = [self cstringWithString:args[idx++]];
    String nickName       = [self cstringWithString:args[idx++]];
    String url            = [self cstringWithString:args[idx++]];
    String IPAddress      = [self cstringWithString:args[idx++]];
    long   location       = [args[idx++] longValue];
    String payPasswd      = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json payloadJson = mainchainSubWallet->GenerateProducerPayload(publicKey, nodePublicKey, nickName, url, IPAddress, location, payPasswd);
        NSString *jsonString = [self stringWithJson:payloadJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)generateCancelProducerPayload:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;
    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String publicKey      = [self cstringWithString:args[idx++]];
    String payPasswd      = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        String payloadJson = mainchainSubWallet->GenerateCancelProducerPayload(publicKey, payPasswd);
        NSString *jsonString = [self stringWithJson:payloadJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createRegisterProducerTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithString:args[idx++]];
    String amount         = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->CreateRegisterProducerTransaction(fromAddress, payloadJson, amount, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createUpdateProducerTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->CreateUpdateProducerTransaction(fromAddress, payloadJson, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createCancelProducerTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson =  mainchainSubWallet->CreateCancelProducerTransaction(fromAddress, payloadJson, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createRetrieveDepositTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String amount         = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson =  mainchainSubWallet->CreateRetrieveDepositTransaction(amount, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getOwnerPublicKey:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    String msg = mainchainSubWallet->GetOwnerPublicKey();
    NSString *jsonString = [self stringWithCString:msg];
    return [self successAsString:command msg:jsonString];
}

- (void)createVoteProducerTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID  = [self cstringWithString:args[idx++]];
    String chainID         = [self cstringWithString:args[idx++]];
    String fromAddress     = [self cstringWithString:args[idx++]];
    String stake           = [self cstringWithString:args[idx++]];
    Json publicKeys        = [self jsonWithString:args[idx++]];
    String memo            = [self cstringWithString:args[idx++]];
    Json invalidCandidates = Json::parse("[]");

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->CreateVoteProducerTransaction(fromAddress, stake, publicKeys, memo, invalidCandidates);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getVotedProducerList:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = mainchainSubWallet->GetVotedProducerList();
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getRegisteredProducerInfo:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = mainchainSubWallet->GetRegisteredProducerInfo();
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

// CR
- (void)generateCRInfoPayload:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;
    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String crPublicKey    = [self cstringWithString:args[idx++]];
    String did            = [self cstringWithString:args[idx++]];
    String nickName       = [self cstringWithString:args[idx++]];
    String url            = [self cstringWithString:args[idx++]];
    long   location       = [args[idx++] longValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json payloadJson = mainchainSubWallet->GenerateCRInfoPayload(crPublicKey, did, nickName, url, location);
        NSString *jsonString = [self stringWithJson:payloadJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)generateUnregisterCRPayload:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;
    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String did            = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json payloadJson = mainchainSubWallet->GenerateUnregisterCRPayload(did);
        NSString *jsonString = [self stringWithJson:payloadJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createRegisterCRTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;
    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithString:args[idx++]];
    String amount         = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->CreateRegisterCRTransaction(fromAddress, payloadJson, amount, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createUpdateCRTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->CreateUpdateCRTransaction(fromAddress, payloadJson, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createUnregisterCRTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String fromAddress    = [self cstringWithString:args[idx++]];
    Json payloadJson      = [self jsonWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson =  mainchainSubWallet->CreateUnregisterCRTransaction(fromAddress, payloadJson, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createRetrieveCRDepositTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];
    String crPublicKey    = [self cstringWithString:args[idx++]];
    String amount         = [self cstringWithString:args[idx++]];
    String memo           = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson =  mainchainSubWallet->CreateRetrieveCRDepositTransaction(crPublicKey, amount, memo);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createVoteCRTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID  = [self cstringWithString:args[idx++]];
    String chainID         = [self cstringWithString:args[idx++]];
    String fromAddress     = [self cstringWithString:args[idx++]];
    Json publicKeys        = [self jsonWithDict:args[idx++]];
    String memo            = [self cstringWithString:args[idx++]];
    Json invalidCandidates = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->CreateVoteCRTransaction(fromAddress, publicKeys, memo, invalidCandidates);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getVotedCRList:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = mainchainSubWallet->GetVotedCRList();
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getRegisteredCRInfo:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID        = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json json = mainchainSubWallet->GetRegisteredCRInfo();
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getVoteInfo:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID  = [self cstringWithString:args[idx++]];
    String chainID         = [self cstringWithString:args[idx++]];
    String type            = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json txJson = mainchainSubWallet->GetVoteInfo(type);
        NSString *jsonString = [self stringWithJson:txJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalOwnerDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    String payload          = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if (mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalOwnerDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalCRCouncilMemberDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID       = [self cstringWithString:args[idx++]];
    String chainID              = [self cstringWithString:args[idx++]];
    String payload              = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalCRCouncilMemberDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)calculateProposalHash:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID       = [self cstringWithString:args[idx++]];
    String chainID              = [self cstringWithString:args[idx++]];
    String payload              = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CalculateProposalHash(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createProposalTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    Json crSignedProposal   = [self jsonWithString:args[idx++]];
    String memo             = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CreateProposalTransaction(crSignedProposal, memo);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalReviewDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    String payload          = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalReviewDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createProposalReviewTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    Json payload            = [self jsonWithString:args[idx++]];
    String memo             = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CreateProposalReviewTransaction(payload, memo);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalTrackingOwnerDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    Json payload            = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalTrackingOwnerDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalTrackingNewOwnerDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    Json payload            = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalTrackingNewOwnerDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalTrackingSecretaryDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    Json payload            = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalTrackingSecretaryDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)proposalWithdrawDigest:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    Json payload            = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->ProposalWithdrawDigest(payload);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createProposalWithdrawTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    String recipient        = [self cstringWithString:args[idx++]];
    String amount           = [self cstringWithString:args[idx++]];
    String utxo             = [self cstringWithString:args[idx++]];
    String payload          = [self cstringWithString:args[idx++]];
    String memo             = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CreateProposalWithdrawTransaction(recipient, amount, utxo, payload, memo);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createVoteCRCProposalTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    String fromAddress      = [self cstringWithString:args[idx++]];
    Json votes              = [self jsonWithString:args[idx++]];
    String memo             = [self cstringWithString:args[idx++]];
    Json invalidCandidates  = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CreateVoteCRCProposalTransaction(fromAddress, votes, memo, invalidCandidates);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createImpeachmentCRCTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    String fromAddress      = [self cstringWithString:args[idx++]];
    Json votes              = [self jsonWithString:args[idx++]];
    String memo             = [self cstringWithString:args[idx++]];
    Json invalidCandidates  = [self jsonWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CreateImpeachmentCRCTransaction(fromAddress, votes, memo, invalidCandidates);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)createProposalTrackingTransaction:(CDVInvokedUrlCommand *)command
{
    int idx = 0;
    NSArray *args = command.arguments;

    String masterWalletID   = [self cstringWithString:args[idx++]];
    String chainID          = [self cstringWithString:args[idx++]];
    String proposalTracking = [self cstringWithString:args[idx++]];
    String memo             = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }
    IMainchainSubWallet *mainchainSubWallet = dynamic_cast<IMainchainSubWallet *>(subWallet);
    if(mainchainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", [self formatWalletNameWithString:masterWalletID other:chainID], @" is not instance of IMainchainSubWallet"];
        return [self errorProcess:command code:errCodeSubWalletInstance msg:msg];
    }

    try {
        Json stringJson = mainchainSubWallet->CreateProposalTrackingTransaction(proposalTracking, memo);
        NSString *jsonString = [self stringWithJson:stringJson];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)syncStart:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID       = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    subWallet->SyncStart();
    return [self successAsString:command msg:@"SyncStart OK"];
}

- (void)syncStop:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID       = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    subWallet->SyncStop();
    return [self successAsString:command msg:@"SyncStop OK"];
}

- (void)reSync:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String chainID       = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    ISubWallet *subWallet = [self getSubWallet:masterWalletID :chainID];
    if (subWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:chainID]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    subWallet->Resync();
    return [self successAsString:command msg:@"SyncStop OK"];
}

String const IDChain = "IDChain";

- (IIDChainSubWallet*) getIDChainSubWallet:(String)masterWalletID {
     ISubWallet* subWallet = [self getSubWallet:masterWalletID :IDChain];

    return dynamic_cast<IIDChainSubWallet *>(subWallet);
 }

- (void)getAllDID:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    int start = [args[idx++] intValue];
    int count = [args[idx++] intValue];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IIDChainSubWallet* idChainSubWallet = [self getIDChainSubWallet:masterWalletID];
    if (idChainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:IDChain]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Json json = idChainSubWallet->GetAllDID(start, count);
        NSString *jsonString = [self stringWithJson:json];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)didSign:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String did            = [self cstringWithString:args[idx++]];
    String message        = [self cstringWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IIDChainSubWallet* idChainSubWallet = [self getIDChainSubWallet:masterWalletID];
    if (idChainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:IDChain]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        String ret = idChainSubWallet->Sign(did, message, payPassword);
        NSString *jsonString = [self stringWithJson:ret];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)didSignDigest:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String did            = [self cstringWithString:args[idx++]];
    String digest        = [self cstringWithString:args[idx++]];
    String payPassword    = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IIDChainSubWallet* idChainSubWallet = [self getIDChainSubWallet:masterWalletID];
    if (idChainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:IDChain]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        String ret = idChainSubWallet->SignDigest(did, digest, payPassword);
        NSString *jsonString = [self stringWithJson:ret];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)verifySignature:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String publicKey            = [self cstringWithString:args[idx++]];
    String message        = [self cstringWithString:args[idx++]];
    String signature    = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IIDChainSubWallet* idChainSubWallet = [self getIDChainSubWallet:masterWalletID];
    if (idChainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:IDChain]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        Boolean ret = idChainSubWallet->VerifySignature(publicKey, message, signature);
        CDVPluginResult*  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:ret];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

- (void)getPublicKeyDID:(CDVInvokedUrlCommand *)command
{
    NSArray *args = command.arguments;
    int idx = 0;

    String masterWalletID = [self cstringWithString:args[idx++]];
    String publicKey            = [self cstringWithString:args[idx++]];

    if (args.count != idx) {
        return [self errCodeInvalidArg:command code:errCodeInvalidArg idx:idx];
    }
    IIDChainSubWallet* idChainSubWallet = [self getIDChainSubWallet:masterWalletID];
    if (idChainSubWallet == nil) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@", @"Get", [self formatWalletNameWithString:masterWalletID other:IDChain]];
        return [self errorProcess:command code:errCodeInvalidSubWallet msg:msg];
    }

    try {
        String ret = idChainSubWallet->GetPublicKeyDID(publicKey);
        NSString *jsonString = [self stringWithJson:ret];
        return [self successAsString:command msg:jsonString];
    } catch (const std:: exception &e) {
        return [self exceptionProcess:command string:e.what()];
    }
}

@end
