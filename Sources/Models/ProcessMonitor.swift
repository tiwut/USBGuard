import Foundation
import Darwin

@_silgen_name("proc_listpids")
func proc_listpids(_ type: UInt32, _ typeinfo: UInt32, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32

@_silgen_name("proc_pidpath")
func proc_pidpath(_ pid: Int32, _ buffer: UnsafeMutableRawPointer, _ buffersize: UInt32) -> Int32

@_silgen_name("proc_name")
func proc_name(_ pid: Int32, _ buffer: UnsafeMutableRawPointer, _ buffersize: UInt32) -> Int32

let PROC_ALL_PIDS: UInt32 = 1
let PROC_PIDPATHINFO_MAXSIZE: UInt32 = 1024

public struct ProcessInfo: Identifiable, Hashable {
    public let id: Int32
    public let name: String
    public let path: String
}

public class ProcessMonitor {
    
    public static let shared = ProcessMonitor()
    
    private init() {}
    
    public func getProcesses(originatingFrom volumePath: String) -> [ProcessInfo] {
        let bufferSize = proc_listpids(PROC_ALL_PIDS, 0, nil, 0)
        guard bufferSize > 0 else { return [] }
        
        var pids = [Int32](repeating: 0, count: Int(bufferSize) / MemoryLayout<Int32>.stride)
        let actualSize = proc_listpids(PROC_ALL_PIDS, 0, &pids, bufferSize)
        let count = actualSize / Int32(MemoryLayout<Int32>.stride)
        
        var results: [ProcessInfo] = []
        var pathBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
        
        let pathWithSlash = volumePath.hasSuffix("/") ? volumePath : volumePath + "/"
        
        for i in 0..<Int(count) {
            let pid = pids[i]
            guard pid > 0 else { continue }
            
            let length = proc_pidpath(pid, &pathBuffer, PROC_PIDPATHINFO_MAXSIZE)
            if length > 0 {
                let path = String(cString: pathBuffer)
                if path.hasPrefix(pathWithSlash) {
                    var nameBuffer = [CChar](repeating: 0, count: 256)
                    proc_name(pid, &nameBuffer, 256)
                    var name = String(cString: nameBuffer)
                    if name.isEmpty {
                        name = (path as NSString).lastPathComponent
                    }
                    results.append(ProcessInfo(id: pid, name: name, path: path))
                }
            }
        }
        
        return results.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }
    
    public func killProcess(pid: Int32) {
        kill(pid, SIGKILL)
    }
    
    public func killAllProcesses(pids: [Int32]) {
        for pid in pids {
            killProcess(pid: pid)
        }
    }
}
