#ifndef BRIDGE_H
#define BRIDGE_H

#include <libavcodec/avcodec.h>
#include <libavcodec/bsf.h>
#include <libavcodec/codec_par.h>
#include <libavcodec/packet.h>
#include <libavcodec/mediacodec.h>
#include <libavcodec/jni.h>

#include <libavdevice/avdevice.h>

#include <libavfilter/avfilter.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>

#include <libavformat/avformat.h>
#include <libavformat/avio.h>

#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <libavutil/avutil.h>
#include <libavutil/buffer.h>
#include <libavutil/channel_layout.h>
#include <libavutil/common.h>
#include <libavutil/dict.h>
#include <libavutil/error.h>
#include <libavutil/opt.h>
#include <libavutil/file.h>
#include <libavutil/log.h>
#include <libavutil/mathematics.h>
#include <libavutil/mem.h>
#include <libavutil/timestamp.h>
#include <libavutil/pixdesc.h>
#include <libavutil/rational.h>
#include <libavutil/imgutils.h>
#include <libavutil/channel_layout.h>
#include <libavutil/md5.h>
#include <libavutil/mastering_display_metadata.h>

#include <libswresample/swresample.h>
#include <libswscale/swscale.h>

#endif
