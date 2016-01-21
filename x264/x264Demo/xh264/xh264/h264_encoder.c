//
//  h264_encoder.c
//  xh264
//
//  Created by user on 14-12-16.
//  Copyright (c) 2014Âπ¥ jwl. All rights reserved.
//

#include "h264_encoder.h"
//#include "my_malloc.h"


//added by zhengxuefeng,2014-12£¨◊‘∂®“Â»’÷æ ‰≥ˆ∫Ø ˝
/*void my_Uart_Printf(const char *fmt, va_list ap)
{
    char string[300];
    vsprintf(string,fmt,ap);
    Uart_SendString(string);
}


static void my_x264_log_default( void *p_unused, int i_level, const char *psz_fmt, va_list arg )
{
    char *psz_prefix;
    switch( i_level )
    {
        case X264_LOG_ERROR:
            psz_prefix = "error";
            break;
        case X264_LOG_WARNING:
            psz_prefix = "warning";
            break;
        case X264_LOG_INFO:
            psz_prefix = "info";
            break;
        case X264_LOG_DEBUG:
            psz_prefix = "debug";
            break;
        default:
            psz_prefix = "unknown";
            break;
    }

	
    Uart_Printf( "x264 [%s]: ", psz_prefix );
    my_Uart_Printf( psz_fmt, arg );
    Uart_Printf( "\r\n " );
}*/


static void my_x264_log_default( void *p_unused, int i_level, const char *psz_fmt, va_list arg )
{
    char *psz_prefix;
    switch( i_level )
    {
        case X264_LOG_ERROR:
            psz_prefix = "error";
            break;
        case X264_LOG_WARNING:
            psz_prefix = "warning";
            break;
        case X264_LOG_INFO:
            psz_prefix = "info";
            break;
        case X264_LOG_DEBUG:
            psz_prefix = "debug";
            break;
        default:
            psz_prefix = "unknown";
            break;
    }
    
    
    printf( "x264 [%s]: ", psz_prefix );
    printf( psz_fmt, arg );
    printf( "\r\n " );
}

void _compress_begin(Encoder *en, int width, int height)
{
    if(x264_param_default_preset(&en->param, "superfast", "zerolatency") < 0)
        return;
    
    en->param.i_width = width;
    en->param.i_height = height;
    //en->param.pf_log = my_x264_log_default;
    en->param.i_log_level = X264_LOG_DEBUG;
    
    /*en->param.i_frame_total  = 0;
     en->param.i_keyint_max = 10;
     
     en->param.i_bframe = 5;
     en->param.b_open_gop = 0;
     en->param.i_bframe_pyramid = 0;
     en->param.i_bframe_adaptive = X264_B_ADAPT_TRELLIS;
     
     en->param.rc.i_bitrate = 1024*10;
     
     en->param.i_fps_den = 1;
     en->param.i_fps_num = 10;
     en->param.i_timebase_den = en->param.i_fps_num;
     en->param.i_timebase_num = en->param.i_fps_den;
     */
    //?
    //Configure non-default params
    //en->param.i_csp = X264_CSP_I420;
    //en->param.b_vfr_input = 0;
    //en->param.b_repeat_headers = 1;
    //en->param.b_annexb = 1;
    //en->param.i_sync_lookahead =
    //en->param.i_threads = X264_SYNC_LOOKAHEAD_AUTO;
    
    /*en->param.i_threads = 1;
     en->param.b_cabac =0;
     en->param.i_bframe =0;
     en->param.b_interlaced=0;
     en->param.rc.i_rc_method = X264_RC_ABR; //X264_RC_CQP
     en->param.i_level_idc=21;
     en->param.rc.i_bitrate=128;
     en->param.b_intra_refresh = 1;
     en->param.b_annexb = 1;
     en->param.i_keyint_max=25;
     en->param.i_fps_num=15;
     en->param.i_fps_den=1;
     en->param.b_annexb = 1;*/
    
    int m_frameRate = 5, m_bitRate = 4000;
    //使用实时视频传输时，需要实时发送sps,pps数据
    en->param.b_repeat_headers = 1;  //重复SPS/PPS放到关键帧前面
    en->param.b_cabac = 1;
    en->param.i_threads = 1;
    
    //将I帧间隔与帧率挂钩的,以控制I帧始终在指定时间内刷新,以下是2秒刷新一个I帧
    en->param.i_fps_num = (int)m_frameRate;
    en->param.i_fps_den = 1;
    en->param.i_keyint_max = m_frameRate * 2;
    //图像质量控制
    //param.rc.b_mb_tree=0;//找个不为0,将导致编码延时帧...在实时编码时,必须为0
    en->param.rc.f_rf_constant = 25;
    en->param.rc.f_rf_constant_max = 45;
    //码率控制
    en->param.rc.i_rc_method = X264_RC_ABR;//参数i_rc_method表示码率控制，CQP(恒定质量)，CRF(恒定码率)，ABR(平均码率)
    //param.rc.f_rate_tolerance=0.1;
    en->param.rc.i_vbv_max_bitrate=(int)((m_bitRate*1.2)/1000) ; // 平均码率模式下，最大瞬时码率，默认0(与-B设置相同)
    en->param.rc.i_vbv_buffer_size = en->param.rc.i_vbv_max_bitrate;
    en->param.rc.i_bitrate = (int)m_bitRate/1000;
    //编码复杂度
    en->param.i_level_idc=30;
    
    // Apply profile restrictions
    if( x264_param_apply_profile(&en->param, x264_profile_names[0] ) < 0 )
        return;
    if((en->handle = x264_encoder_open(&en->param)) == 0)
        return;
    
    /* Create a new pic */
    if(x264_picture_alloc(&en->picture, X264_CSP_I420, en->param.i_width, en->param.i_height) < 0)
        return;
    en->picture.img.i_csp = en->param.i_csp;
    en->picture.img.i_plane = 3;

    
}


int _compress_frame(Encoder *en, int type, uint8_t *inYuv422, uint8_t *outBuf)
{
    x264_picture_t pic_out;
    int nNal = -1;
    int result = 0;
    int i = 0;
    uint8_t *p_out = outBuf;
    uint8_t *y = en->picture.img.plane[0];
    uint8_t *u = en->picture.img.plane[1];
    uint8_t *v = en->picture.img.plane[2];
    int is_y = 1, is_u = 1;
    int y_index = 0, u_index = 0, v_index = 0;
    int yuv422_length = 2 * en->param.i_width * en->param.i_height;
    for (i = 0; i < yuv422_length; ++i)
    {
        if (is_y)
        {
            *(y + y_index) = *(inYuv422 + i);
            ++y_index;
            is_y = 0;
        }
        else
        {
            if (is_u)
            {
                *(u + u_index) = *(inYuv422 + i);
                ++u_index;
                is_u = 0;
            }
            else
            {
                *(v + v_index) = *(inYuv422 + i);
                ++v_index;
                is_u = 1;
            }
            is_y = 1;
        }
    }
    
    switch(type)
    {
        case 0:
            en->picture.i_type = X264_TYPE_P;
            break;
        case 1:
            en->picture.i_type = X264_TYPE_IDR;
            break;
        case 2:
            en->picture.i_type = X264_TYPE_I;
            break;
        default:
            en->picture.i_type = X264_TYPE_AUTO;
            break;
    }
    
    if (x264_encoder_encode(en->handle, &(en->nal), &nNal, &en->picture, &pic_out) < 0)
    {
        return -1;
    }
    
    en->picture.i_pts++;
    for (i = 0; i < nNal; i++)
    {
        memcpy(p_out, en->nal[i].p_payload, en->nal[i].i_payload);
        p_out += en->nal[i].i_payload;
        result += en->nal[i].i_payload;
    }
    
    return result;
}

int _compress_frame_2(Encoder *en, int type, uint8_t *inYuv420p, uint8_t *outBuf)
{
    x264_picture_t pic_out;
    int nNal = -1;
    int result = 0;
    int i = 0;
    uint8_t *p_out = outBuf;
    uint8_t *y = en->picture.img.plane[0];
    uint8_t *u = en->picture.img.plane[1];
    uint8_t *v = en->picture.img.plane[2];
    
    
    memcpy(y, inYuv420p, en->param.i_width * en->param.i_height);
    memcpy(u, inYuv420p + en->param.i_width * en->param.i_height, en->param.i_width * en->param.i_height/4);
    memcpy(v, inYuv420p + en->param.i_width * en->param.i_height*5/4, en->param.i_width * en->param.i_height/4);
    
    
    switch(type)
    {
        case 0:
            en->picture.i_type = X264_TYPE_P;
            break;
        case 1:
            en->picture.i_type = X264_TYPE_IDR;
            break;
        case 2:
            en->picture.i_type = X264_TYPE_I;
            break;
        default:
            en->picture.i_type = X264_TYPE_AUTO;
            break;
    }

    if (x264_encoder_encode(en->handle, &(en->nal), &nNal, &en->picture, &pic_out) < 0)
    {
        return -1;
    }

    en->picture.i_pts++;
    for (i = 0; i < nNal; i++)
    {
        memcpy(p_out, en->nal[i].p_payload, en->nal[i].i_payload);
        p_out += en->nal[i].i_payload;
        result += en->nal[i].i_payload;
    }
    
    return result;
}

void _compress_end(Encoder *en)
{
    
    x264_picture_clean(&en->picture);
    
    if(en->handle)
    {
        x264_encoder_close(en->handle);
        en->handle = NULL;
    }
    
}


/*void init_x264_mem_pool(void)
{
	init_my_mem();
}*/

static Encoder en;

void compress_begin(int width, int height)
{
    _compress_begin(&en, width, height);
}

int  compress_frame(unsigned char *inYuv422, unsigned char *outH264)
{
    return _compress_frame(&en, -1, inYuv422, outH264);
}

int  compress_frame_2(unsigned char *inYuv420p, unsigned char *outH264)
{
    return _compress_frame_2(&en, -1, inYuv420p, outH264);
}

void compress_end()
{
    _compress_end(&en);
}


