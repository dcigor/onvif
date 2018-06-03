//
//  IdiaVideoSource.hpp
//  Background
//
//  Created by Igor Diakov on 6/2/18.
//  Copyright © 2018 IgorDiakov. All rights reserved.
//

#ifndef IdiaVideoSource_hpp
#define IdiaVideoSource_hpp

#include <condition_variable>
#include <mutex>
#include <string>
#include <thread>

struct AVCodecContext;
struct AVFrame;

class IIdiaVideoDelegate {
public:
    virtual void onError(const char*) = 0;
    virtual void onImage(const uint8_t *bytes, int w, int h, int bytesPerRow) = 0;
};

class IdiaVideoSource {
public:
    IdiaVideoSource(IIdiaVideoDelegate *delegate);
    int open(const char* url, const char* username, const char* password);
    int stop();
private:
    // these are called from the worker thread
    void threadProc();

    static int g_interrupt_callback(void*p);
    int interrupt_callback();
    
    void reportError(int error);
    void reportError(const char*);
    void deliverImage(AVFrame *pFrameRGB, int width, int height);

    IIdiaVideoDelegate *delegate_ = nullptr;
    volatile bool isStopped_     = false;
    std::string url_;
    std::thread thread_;
    std::mutex mutex_;
    std::condition_variable cond_;
};

#endif /* IdiaVideoSource_hpp */
