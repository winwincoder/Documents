//
//  ffcodec.c
//  ffLibDemo
//
//  Created by user on 15-5-7.
//  Copyright (c) 2015年 jwl. All rights reserved.
//

#include "ffcodec.h"

#include "yuv2rgb.h"


AVCodec           *pCodec = NULL;
AVCodecContext    *pCodecCtx = NULL;
AVFrame           *pFrame = NULL;
AVFrame           *pFrame2 = NULL;
char              *pFrame2Buf = NULL;


//h264码流解析相关
AVCodecParserContext *parser = NULL;
pNaluDataCallbackFunc naluOutputFunc = NULL;

//格式转换相关
struct SwsContext *img_convert_ctx = NULL;


//其它格式装换为yuv420p格式转换接口,必须在解码后调用
int AVFrame2Yuv420P(AVCodecContext *pDecCtx, AVFrame* pInFrame, AVFrame* pOutFrame)
{
    if(img_convert_ctx == NULL) {
        
        int frame_size = avpicture_get_size(AV_PIX_FMT_YUV420P,  pDecCtx->width, pDecCtx->height);
        pFrame2Buf = av_malloc(frame_size);
        avpicture_fill((AVPicture *)pFrame2, (const uint8_t *)pFrame2Buf, AV_PIX_FMT_YUV420P, pDecCtx->width, pDecCtx->height);
        
        img_convert_ctx = sws_getContext(pDecCtx->width, pDecCtx->height, pDecCtx->pix_fmt, pDecCtx->width, pDecCtx->height, AV_PIX_FMT_YUV420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        if (img_convert_ctx == NULL) {
            
            printf("can't init convert context!\n");
            return -1;
        }
    }
    
    sws_scale(img_convert_ctx, (const uint8_t * const*)pInFrame->data, pInFrame->linesize,
              0, pCodecCtx->height, pOutFrame->data, pOutFrame->linesize);

    return 0;
}



void ff_registerAll() {
    
    avcodec_register_all();
}

//AV_CODEC_ID_H264， AV_CODEC_ID_MJPEG
int ff_openH264Dec(pNaluDataCallbackFunc pFunc, enum AVCodecID dec_id) {
    
    pCodec = avcodec_find_decoder(dec_id);
    if (!pCodec) {
        fprintf(stderr, "h264 decoder can not be found!\n");
        
        return -1;
    }
    
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if (!pCodecCtx) {
        fprintf(stderr, "Could not allocate video codec context\n");
        return -1;
    }
    
    //当给入的待解码数据不是以完整帧给入时，相当于是起到一个数据缓冲的作用
    //if(pCodec->capabilities&CODEC_CAP_TRUNCATED)
    //    pCodecCtx->flags|= CODEC_FLAG_TRUNCATED;
    
    
    /* open the coderc */
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        fprintf(stderr, "could not open codec\n");
        
        return -1;
    }
    
    parser = av_parser_init(pCodecCtx->codec_id);
    parser->flags |= PARSER_FLAG_ONCE;  //在打开解码器后初始化parse
    
    naluOutputFunc = pFunc;
    
    // Allocate video frame
    pFrame = av_frame_alloc();
    if(!pFrame) {
        fprintf(stderr, "Could not allocate video frame 1\n");
        return -1;
    }
    
    pFrame2 = av_frame_alloc();
    if(!pFrame2) {
        fprintf(stderr, "Could not allocate video frame 2\n");
        return -1;
    }
    

    
    return 0;
}


int ff_h264_decode(unsigned char* pInNaluBuf, int inLen, unsigned char *pOutRgbaBuf, int *pw, int *ph)
{
    if(!pCodecCtx)
        return -1;
    
    AVPacket avpkt;
    av_init_packet(&avpkt);
    
    avpkt.size = inLen;
    avpkt.data = pInNaluBuf;
    
    int ret, got_frame;
    
    ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_frame, &avpkt);
    if (ret < 0) {
        return -1;
    }
    
    if (got_frame) {
        
        
        *pw = pCodecCtx->width;
        *ph = pCodecCtx->height;
        //将yuv格式数据转换为目标格式抛出
        //ret = AVFrame2Rgba(pFrame, pOutRgbaBuf, pw, ph);
        yuv420_2_rgb8888(pOutRgbaBuf, pFrame->data[0], pFrame->data[1], pFrame->data[2], pCodecCtx->width, pCodecCtx->height,  pCodecCtx->width, pCodecCtx->width/2, pCodecCtx->width*4,yuv2rgb565_table, 0);

    }
    
    av_free_packet(&avpkt);
    
    return ret;
}

AVFrame * ff_h264_decode_2(unsigned char* pInNaluBuf, int inLen, int *pw, int *ph)
{
    
    if(!pCodecCtx)
        return NULL;
    
    AVPacket avpkt;
    av_init_packet(&avpkt);
    
    avpkt.size = inLen;
    avpkt.data = pInNaluBuf;
    
    int ret, got_frame;
    
    ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_frame, &avpkt);
    
    av_free_packet(&avpkt);
    
    if (ret < 0) {
        return NULL;
    }
    
    if (got_frame) {

        *pw = pCodecCtx->width;
        *ph = pCodecCtx->height;
        
        if(pCodecCtx->pix_fmt != AV_PIX_FMT_YUV420P)
        {
            if(0 == AVFrame2Yuv420P(pCodecCtx, pFrame, pFrame2))
            {
                return pFrame2;
            }
        }
        else
        {
            return pFrame;
        }
        
    }
    
    
    return NULL;
}




int ff_h264_AnnexB_parse(unsigned char *inBuf, int inLen) {
    
    if(!pCodecCtx)
        return -1;

    unsigned char *temp_in_buf = inBuf;
    int temp_in_len = inLen;
    
    if(temp_in_len == 0)  //h264码流结束
    {
        unsigned char *data = 0;
        int size = 0;
        av_parser_parse2(parser, pCodecCtx, (uint8_t**)&data, &size, temp_in_buf, temp_in_len, AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);
        
        if(size)
        {
            if(naluOutputFunc != NULL)
            {
                naluOutputFunc(data, size);
                
            }
         }

    }
    else if(temp_in_len > 0)
    {
    
        while(temp_in_len) {
            
            unsigned char *data = 0;
            int size = 0;
            
            int len = av_parser_parse2(parser, pCodecCtx, (uint8_t**)&data, &size, temp_in_buf, temp_in_len, AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);
            temp_in_buf += len;
            temp_in_len -= len;
            
            if(size)
            {
                if(naluOutputFunc != NULL)
                {
                    naluOutputFunc(data, size);
                }
            }
        }
    }
    
    return 0;
}


void ff_closeH264Dec() {
    
    if(parser) {
        
        av_parser_close(parser);
        parser = NULL;
    }
    
    if(pFrame) {
        
        av_frame_free(&pFrame);
        pFrame = NULL;
    }
    
    if(pFrame2) {
        
        av_frame_free(&pFrame2);
        pFrame2 = NULL;
    }
    
    if(pFrame2Buf) {
        
        av_free(pFrame2Buf);
        pFrame2Buf = NULL;
    }

    if(img_convert_ctx) {
        
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
    }
    
    if(pCodecCtx) {
        
        avcodec_close(pCodecCtx);
        av_free(pCodecCtx);
        pCodecCtx = NULL;
    }

}






