//
//  h264_encoder.h
//  xh264
//
//  Created by user on 14-12-16.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#ifndef xh264_h264_encoder_h
#define xh264_h264_encoder_h

#include "common/common.h"

typedef struct {
    x264_param_t param;
    x264_t *handle;
    x264_picture_t picture;
    x264_nal_t *nal;
}Encoder;


//void init_x264_mem_pool(void);
void compress_begin(int width, int height);
int  compress_frame(unsigned char *inYuv422, unsigned char *outH264);
int  compress_frame_2(unsigned char *inYuv420p, unsigned char *outH264);
void compress_end();


#endif
