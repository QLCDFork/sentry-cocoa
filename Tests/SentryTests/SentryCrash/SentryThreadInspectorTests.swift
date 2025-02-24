import SentryTestUtils
import XCTest

class SentryThreadInspectorTests: XCTestCase {
    
    private class Fixture {
        var testMachineContextWrapper = TestMachineContextWrapper()
        var stacktraceBuilder = TestSentryStacktraceBuilder(crashStackEntryMapper: SentryCrashStackEntryMapper(inAppLogic: SentryInAppLogic(inAppIncludes: [], inAppExcludes: [])))
        var keepThreadAlive = true
        
        func getSut(testWithRealMachineContextWrapper: Bool = false, symbolicate: Bool = true) -> SentryThreadInspector {
            
            let machineContextWrapper = testWithRealMachineContextWrapper ? SentryCrashDefaultMachineContextWrapper() : testMachineContextWrapper as SentryCrashMachineContextWrapper
            let stacktraceBuilder = testWithRealMachineContextWrapper ? SentryStacktraceBuilder(crashStackEntryMapper: SentryCrashStackEntryMapper(inAppLogic: SentryInAppLogic(inAppIncludes: [], inAppExcludes: []))) : self.stacktraceBuilder

            stacktraceBuilder.symbolicate = symbolicate

            return SentryThreadInspector(
                stacktraceBuilder: stacktraceBuilder,
                andMachineContextWrapper: machineContextWrapper, symbolicate: symbolicate
            )
        }
    }
    
    private var fixture: Fixture!
    
    override  func setUp() {
        super.setUp()
        fixture = Fixture()
    }

    override class func tearDown() {
        super.tearDown()
        clearTestState()
    }
    
    func testNoThreads() {
        let actual = fixture.getSut().getCurrentThreads()
        XCTAssertEqual(0, actual.count)
    }
    
    func testStacktraceHasFrames() throws {
        let actual = fixture.getSut(testWithRealMachineContextWrapper: true).getCurrentThreads()
        let stacktrace = try XCTUnwrap(actual.first).stacktrace
        
        // The stacktrace has usually more than 40 frames. Feel free to change the number if the tests are failing
        XCTAssertTrue(30 < stacktrace?.frames.count ?? 0, "Not enough stacktrace frames.")
    }
    
    func testGetCurrentThreadsWithStacktrace_WithSymbolication() {
        let queue = DispatchQueue(label: "test-queue", attributes: [.concurrent, .initiallyInactive])
        
        let expect = expectation(description: "Read every thread")
        expect.expectedFulfillmentCount = 10
        
        let sut = self.fixture.getSut(testWithRealMachineContextWrapper: true)
        for _ in 0..<10 {
            
            queue.async {
                let actual = sut.getCurrentThreadsWithStackTrace()
                
                // Sometimes during tests its possible to have one thread without frames
                // We just need to make sure we retrieve frame information for at least one other thread than the main thread
                var threadsWithFrames = 0
                
                for thr in actual {
                    if (thr.stacktrace?.frames.count ?? 0) >= 1 {
                        threadsWithFrames += 1
                    }
                    
                    for frame in thr.stacktrace?.frames ?? [] {
                        XCTAssertNotNil(frame.instructionAddress)
                        XCTAssertNotNil(frame.imageAddress)
                    }
                }
                
                XCTAssertTrue(threadsWithFrames > 1, "Not enough threads with frames")
                
                expect.fulfill()
            }
        }
        
        queue.activate()
        wait(for: [expect], timeout: 10)
    }
    
    func testGetCurrentThreadsWithStacktrace_WithoutSymbolication() {
        let queue = DispatchQueue(label: "test-queue", attributes: [.concurrent, .initiallyInactive])
        
        let expect = expectation(description: "Read every thread")
        expect.expectedFulfillmentCount = 10
        
        let sut = self.fixture.getSut(testWithRealMachineContextWrapper: true, symbolicate: false)
        
        for _ in 0..<10 {
            
            queue.async {
                let actual = sut.getCurrentThreadsWithStackTrace()
                
                // Sometimes during tests its possible to have one thread without frames
                // We just need to make sure we retrieve frame information for at least one other thread than the main thread
                var threadsWithFrames = 0
                
                for thr in actual {
                    if (thr.stacktrace?.frames.count ?? 0) >= 1 {
                        threadsWithFrames += 1
                    }
                    
                    for frame in thr.stacktrace?.frames ?? [] {
                        XCTAssertNotNil(frame.instructionAddress)
                        XCTAssertNotNil(frame.imageAddress)
                        XCTAssertNil(frame.symbolAddress)
                    }
                }
                
                XCTAssertTrue(threadsWithFrames > 1, "Not enough threads with frames")
                
                expect.fulfill()
            }
        }
        
        queue.activate()
        wait(for: [expect], timeout: 10)
    }

    func testGetCurrentThreadWithStackTrack_TooManyThreads() {
        let expect = expectation(description: "Wait all Threads")
        expect.expectedFulfillmentCount = 70

        let sut = self.fixture.getSut(testWithRealMachineContextWrapper: true)

        let lock = NSLock()
        for _ in 0..<expect.expectedFulfillmentCount {
            Thread.detachNewThread {
                expect.fulfill()
                lock.lock()
                var keepThreadAlive = self.fixture.keepThreadAlive
                lock.unlock()
                while keepThreadAlive {
                    Thread.sleep(forTimeInterval: 0.001)
                    lock.lock()
                    keepThreadAlive = self.fixture.keepThreadAlive
                    lock.unlock()
                }
            }
        }

        wait(for: [expect], timeout: 5)
        let suspendedThreads = sut.getCurrentThreadsWithStackTrace()
        lock.lock()
        fixture.keepThreadAlive = false
        lock.unlock()
        XCTAssertEqual(suspendedThreads.count, 0)
    }

    func testStackTrackForCurrentThreadAsyncUnsafe() {
        guard let stackTrace = fixture.getSut(testWithRealMachineContextWrapper: true).stacktraceForCurrentThreadAsyncUnsafe() else {
            XCTFail("Stack Trace not found")
            return
        }
        let stackTrace2 = fixture.getSut(testWithRealMachineContextWrapper: true).getCurrentThreadsWithStackTrace() 

        XCTAssertNotNil(stackTrace)
        XCTAssertNotNil(stackTrace2)
        XCTAssertGreaterThan(stackTrace.frames.count, 0)
        XCTAssertNotEqual(stackTrace.frames.first?.instructionAddress, "0x0000000000000000")
        XCTAssertNotEqual(stackTrace.frames.first?.function, "<redacted>")
    }

    func testStackTrackForCurrentThreadAsyncUnsafe_NoSymbolication() {
        guard let stackTrace = fixture.getSut(testWithRealMachineContextWrapper: true, symbolicate: false).stacktraceForCurrentThreadAsyncUnsafe() else {
            XCTFail("Stack Trace not found")
            return
        }

        XCTAssertNotNil(stackTrace)
        XCTAssertGreaterThan(stackTrace.frames.count, 0)
        XCTAssertEqual(stackTrace.frames.first?.function, "<redacted>")
    }

    func testOnlyCurrentThreadHasStacktrace() throws {
        let actual = fixture.getSut(testWithRealMachineContextWrapper: true).getCurrentThreads()
        XCTAssertEqual(true, try XCTUnwrap(actual.first).current)
        XCTAssertNotNil(try XCTUnwrap(actual.first).stacktrace)
        
        XCTAssertEqual(false, try XCTUnwrap(actual.element(at: 1)).current)
        XCTAssertNil(try XCTUnwrap(actual.element(at: 1)).stacktrace)
    }
    
    func testOnlyFirstThreadIsCurrent() throws {
        let actual = fixture.getSut(testWithRealMachineContextWrapper: true).getCurrentThreads()
        
        let thread0 = try XCTUnwrap(actual.first)
        XCTAssertEqual(true, thread0.current)
        
        let threadCount = actual.count
        for i in 1..<threadCount {
            XCTAssertEqual(false, actual[i].current)
        }
    }
    
    func testStacktraceOnlyForCurrentThread() throws {
        let actual = fixture.getSut(testWithRealMachineContextWrapper: true).getCurrentThreads()
        
        XCTAssertNotNil(try XCTUnwrap(actual.first).stacktrace)
        
        let threadCount = actual.count
        for i in 1..<threadCount {
            let thread = actual[i]
            XCTAssertNil(thread.stacktrace)
        }
    }
    
    func testCrashedIsFalseForAllThreads() {
        let actual = fixture.getSut(testWithRealMachineContextWrapper: true).getCurrentThreads()
        
        let threadCount = actual.count
        for i in 0..<threadCount {
            XCTAssertEqual(false, actual[i].crashed)
        }
    }
    
    func testThreadName() {
        let threadName = "thread.name123"
        fixture.testMachineContextWrapper.threadCount = 1
        fixture.testMachineContextWrapper.threadName = threadName
        
        let actual = fixture.getSut().getCurrentThreads()
        
        XCTAssertEqual(threadName, try XCTUnwrap(actual.first).name)
    }
    
    func testGetThreadName_EmptyThreadName() throws {
        fixture.testMachineContextWrapper.threadName = ""
        fixture.testMachineContextWrapper.threadCount = 1
        
        let actual = fixture.getSut().getCurrentThreads()
        XCTAssertEqual(1, actual.count)
        
        let thread = try XCTUnwrap(actual.first)
        XCTAssertNil(thread.name)
    }
    
    func testGetThreadNameFails() throws {
        fixture.testMachineContextWrapper.threadName = ""
        fixture.testMachineContextWrapper.getThreadNameSucceeds = false
        fixture.testMachineContextWrapper.threadCount = 1
        
        let actual = fixture.getSut().getCurrentThreads()
        XCTAssertEqual(1, actual.count)
        
        let thread = try XCTUnwrap(actual.first)
        XCTAssertNil(thread.name)
    }
    
    func testLongThreadName() throws {
        let threadName = String(repeating: "1", count: 127)
        fixture.testMachineContextWrapper.threadName = threadName
        fixture.testMachineContextWrapper.threadCount = 1
        
        let actual = fixture.getSut().getCurrentThreads()
        XCTAssertEqual(1, actual.count)
        
        let thread = try XCTUnwrap(actual.first)
        XCTAssertEqual(threadName, thread.name)
    }
    
    func testMainThreadAsFirstThread() {
        fixture.testMachineContextWrapper.mockThreads = [ ThreadInfo(threadId: 2, name: "Second Thread"), ThreadInfo(threadId: 1, name: "main") ]
        fixture.testMachineContextWrapper.mainThread = 1
        fixture.testMachineContextWrapper.threadCount = 2
         
        let sut = fixture.getSut()
        let threads = sut.getCurrentThreads()
        
        XCTAssertEqual(try XCTUnwrap(threads.first).name, "main")
        XCTAssertEqual(try XCTUnwrap(threads.element(at: 1)).name, "Second Thread")
    }

    func testOnlyOneThreadIsMain() {
        fixture.testMachineContextWrapper.mockThreads = [
            ThreadInfo(threadId: 2, name: "Main Thread"),
            ThreadInfo(threadId: 1, name: "First Thread") ]
        fixture.testMachineContextWrapper.mainThread = 2
        fixture.testMachineContextWrapper.threadCount = 2

        let actualThreads = fixture.getSut().getCurrentThreads()

        var actualMainThreadsCount = 0
        var mainThread: SentryThread?
        let threadCount = actualThreads.count
        for i in 0..<threadCount {
            if actualThreads[i].isMain!.boolValue {
                actualMainThreadsCount += 1
                mainThread = actualThreads[i]
            }
        }
        XCTAssertEqual(actualMainThreadsCount, 1)
        XCTAssertEqual(mainThread?.name, "Main Thread")
    }
}

private class TestSentryStacktraceBuilder: SentryStacktraceBuilder {
    
    var stackTraces = [SentryCrashThread: SentryStacktrace]()

    override func buildStacktrace(forThread thread: SentryCrashThread, context: UnsafeMutablePointer<SentryCrashMachineContext>) -> SentryStacktrace {
        return stackTraces[thread] ?? SentryStacktrace(frames: [], registers: [:])
    }
}

private struct ThreadInfo {
    var threadId: SentryCrashThread
    var name: String
}

private class TestMachineContextWrapper: NSObject, SentryCrashMachineContextWrapper {
        
    func fillContext(forCurrentThread context: UnsafeMutablePointer<SentryCrashMachineContext>) {
        // Do nothing
    }
    
    var threadCount: Int32 = 0
    func getThreadCount(_ context: UnsafeMutablePointer<SentryCrashMachineContext>) -> Int32 {
        threadCount
    }
    
    var mockThreads: [ThreadInfo]?
    func getThread(_ context: UnsafeMutablePointer<SentryCrashMachineContext>, with index: Int32) -> SentryCrashThread {
        mockThreads?[Int(index)].threadId ?? 0
    }
    
    var threadName: String = ""
    var getThreadNameSucceeds = true
    func getThreadName(_ thread: SentryCrashThread, andBuffer buffer: UnsafeMutablePointer<Int8>, andBufLength bufLength: Int32) -> Bool {
        if let mocks = mockThreads, let index = mocks.firstIndex(where: { $0.threadId == thread }) {
            strcpy(buffer, mocks[index].name)
            return true
        }
        
        if getThreadNameSucceeds {
            strcpy(buffer, threadName)
            return true
        } else {
            _ = Array(repeating: 0, count: Int(bufLength)).withUnsafeBufferPointer { bufferPointer in
                strcpy(buffer, bufferPointer.baseAddress)
            }
            return false
        }
    }
    
    var mainThread: SentryCrashThread?
    func isMainThread(_ thread: SentryCrashThread) -> Bool {
        return thread == mainThread
    }
}
