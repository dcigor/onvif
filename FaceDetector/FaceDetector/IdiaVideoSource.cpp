//
//  IdiaVideoSource.cpp
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#include "IdiaVideoSource.hpp"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
}

namespace {
    class AVFormatContextCpp {
    public:
        AVFormatContextCpp(AVFormatContext *ctx) : ctx_(ctx), needCloseInput_(false) {}
        ~AVFormatContextCpp() {close();}
        
        operator AVFormatContext*  () {return ctx_;}
        operator AVFormatContext** () {return &ctx_;}
        AVFormatContext* operator->() {return ctx_;}
        void close () {
            if (ctx_) {
                if (needCloseInput_) {
                    avformat_close_input(&ctx_);
                    needCloseInput_ = false;
                }
                avformat_free_context(ctx_);
                ctx_ = nullptr;
            }
        }
        void detach() {ctx_ = nullptr;}
        void attach(AVFormatContext *ctx) {ctx_ = ctx;}
        void setNeedCloseInput(bool value) {needCloseInput_ = value;}
    private:
        AVFormatContext *ctx_;
        bool needCloseInput_;
    };
}

IdiaVideoSource::IdiaVideoSource(IIdiaVideoDelegate *delegate)
:   delegate_(delegate)
{
    static bool isFfmpegInitialized = false;
    if (!isFfmpegInitialized) {
        isFfmpegInitialized = true;
        av_register_all();
        avcodec_register_all();
        avformat_network_init();
    }
}

int IdiaVideoSource::open(const char* url, const char* username, const char* password) {
    // assume "rtsp://" prefix
    url_    = std::string("rtsp://") + username + ":" + password + "@" + (url+7);
    thread_ = std::thread(std::bind(&IdiaVideoSource::threadProc, this));
    return 0;
}

int IdiaVideoSource::stop() {
    isStopped_ = true;
    thread_.join();
    return 0;
}

// implementation
int IdiaVideoSource::g_interrupt_callback(void*p) {
    IdiaVideoSource *v = (IdiaVideoSource*)p;
    return v->interrupt_callback();
}

int IdiaVideoSource::interrupt_callback() {
    return isStopped_;
}

void IdiaVideoSource::reportError(const int error) {
    char msg[AV_ERROR_MAX_STRING_SIZE] = { 0 };
    av_make_error_string(msg, AV_ERROR_MAX_STRING_SIZE, error);
    reportError(msg);
}

void IdiaVideoSource::reportError(const char *message) {
    delegate_->onError(message);
}

void IdiaVideoSource::deliverImage(AVFrame *pFrameRGB, int width, int height) {
    delegate_->onImage(pFrameRGB->data[0], width, height, pFrameRGB->linesize[0]);
}

void IdiaVideoSource::threadProc() {
    AVFormatContextCpp formatCtx(avformat_alloc_context());
    formatCtx->interrupt_callback.callback = g_interrupt_callback;
    formatCtx->interrupt_callback.opaque   = this;

    // open url
    if (const int err = avformat_open_input(formatCtx, url_.c_str(), nullptr, nullptr)) {
        reportError(err);
        return;
    }

    // get stream information
    if (const int err = avformat_find_stream_info(formatCtx, nullptr)) {
        reportError(err);
        return;
    }
    
    // find video stream
    int videoStream = -1;
    AVCodecContext *pCodecCtxIn = nullptr;
    for (int i=0; i<formatCtx->nb_streams; ++i) {
        if (formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            pCodecCtxIn = formatCtx->streams[i]->codec;
            videoStream = i;
            break;
        }
    }
    if (!pCodecCtxIn) {
        reportError("could not find video stream");
        return;
    }

    // find decoder
    AVCodec *pCodec = avcodec_find_decoder(pCodecCtxIn->codec_id);
    if (!pCodec) {
        reportError("unsupported codec");
        return;
    }
    
    AVCodecContext *pCodecCtx = avcodec_alloc_context3(pCodec);
    if (const int err = avcodec_copy_context(pCodecCtx, pCodecCtxIn)) {
        reportError(err);
        return;
    }
    if (const int err = avcodec_open2(pCodecCtx, pCodec, nullptr)) {
        reportError(err);
        return;
    }

    // store the images
    const int w = 800, h = 600;
    AVFrame *pFrame    = av_frame_alloc();
    AVFrame *pFrameRGB = av_frame_alloc();
    const int numBytes = avpicture_get_size(AV_PIX_FMT_RGB24, w, h);
    uint8_t *buffer    = (uint8_t *)av_malloc(numBytes);
    avpicture_fill((AVPicture *)pFrameRGB, buffer, AV_PIX_FMT_RGB24, w, h);

    // read the data
    SwsContext *sws_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
        w, h, AV_PIX_FMT_RGB24, SWS_BILINEAR, nullptr, nullptr, nullptr);

    AVPacket packet;
    while (av_read_frame(formatCtx, &packet)>=0) {
        // Is this a packet from the video stream?
        if (packet.stream_index==videoStream) {
            // Decode video frame
            int frameFinished = 0;
            avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);

            if (frameFinished) {
                sws_scale(sws_ctx, (uint8_t const * const *)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                    pFrameRGB->data, pFrameRGB->linesize);
                deliverImage(pFrameRGB, w, h);
            }
        }

        av_free_packet(&packet);
    }
}
