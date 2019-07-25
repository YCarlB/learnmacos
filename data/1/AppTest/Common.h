//
//  Common.h
//  AppTest
//
//  Created by TanHao on 13-11-2.
//  Copyright (c) 2013年 http://www.tanhao.me. All rights reserved.
//

//四则运算
enum CalculateSelectorCode
{
    kCalculatePlus,
    kCalculateMinus,
    kCalculateMultiply,
    kCalculateDivided
};

//运算的参数
typedef struct CalculateArguments
{
    double va_a;
    double va_b;
}CalculateArguments;

//运算的结果
typedef struct CalculateResult
{
    double va;
}CalculateResult;
