#ifndef SentryProfilingConditionals_h
#define SentryProfilingConditionals_h

#include <TargetConditionals.h>

// tvOS and watchOS do not support the kernel APIs required by our profiler
// e.g. mach_msg, thread_suspend, thread_resume; we haven't yet tested on
// visionOS
#if TARGET_OS_WATCH || TARGET_OS_TV || (defined(TARGET_OS_VISION) && TARGET_OS_VISION)
#    define SENTRY_TARGET_PROFILING_SUPPORTED 0
#else
#    define SENTRY_TARGET_PROFILING_SUPPORTED 1
#endif

#endif /* SentryProfilingConditionals_h */
