//
//  SharedStructures.h
//  ReplayKitSampleGame-Metal
//
//  Created by KyuJin Kim on 2016. 12. 27..
//  Copyright (c) 2016년 KyuJin Kim. All rights reserved.
//

#ifndef SharedStructures_h
#define SharedStructures_h

#include <simd/simd.h>

typedef struct
{
    matrix_float4x4 modelview_projection_matrix;
    matrix_float4x4 normal_matrix;
} uniforms_t;

#endif /* SharedStructures_h */

