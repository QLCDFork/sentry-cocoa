#ifndef CppSample_hpp
#define CppSample_hpp
#if defined __cplusplus

#    include <stdio.h>

namespace Sentry {
class CppSample {
public:
    void throwCPPException();
    void noExceptCppException() noexcept;
    void rethrowNoActiveCPPException();
};
}

#endif /* __cplusplus */
#endif /* CppSample_hpp */
