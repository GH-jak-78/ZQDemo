//
//  LHYMyPointApiManager.h
//  OOLaGongYi
//
//  Created by YueHui on 16/10/25.
//  Copyright © 2016年 GZ Leihou Software Development CO.,LTD. All rights reserved.
//

#import "ZQBaseApiManager.h"

@interface LHYMyPointApiManager : ZQBaseApiManager <ZQApiManagerProtocol>

- (void)changeRequestPolicy:(ZQApiRequestPolicy)apiRequestPolicy;

@end
