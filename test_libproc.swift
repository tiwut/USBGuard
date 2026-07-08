import Foundation

@_silgen_name("proc_listpids")
func proc_listpids(_ type: UInt32, _ typeinfo: UInt32, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32

@_silgen_name("proc_pidpath")
func proc_pidpath(_ pid: Int32, _ buffer: UnsafeMutableRawPointer, _ buffersize: UInt32) -> Int32

@_silgen_name("proc_name")
func proc_name(_ pid: Int32, _ buffer: UnsafeMutableRawPointer, _ buffersize: UInt32) -> Int32

let PROC_ALL_PIDS: UInt32 = 1
let PROC_PIDPATHINFO_MAXSIZE: UInt32 = 1024

func getProcesses() {
    let bufferSize = proc_listpids(PROC_ALL_PIDS, 0, nil, 0)
    var pids = [Int32](repeating: 0, count: Int(bufferSize) / MemoryLayout<Int32>.stride)
    let actualSize = proc_listpids(PROC_ALL_PIDS, 0, &pids, bufferSize)
    let count = actualSize / Int32(MemoryLayout<Int32>.stride)
    
    var pathBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
    
    for i in 0..<min(Int(count), 10) {
        let pid = pids[i]
        guard pid > 0 else { continue }
        
        let length = proc_pidpath(pid, &pathBuffer, PROC_PIDPATHINFO_MAXSIZE)
        if length > 0 {
            let path = String(cString: pathBuffer)
            var nameBuffer = [CChar](repeating: 0, count: 256)
            proc_name(pid, &nameBuffer, 256)
            let name = String(cString: nameBuffer)
            print("PID: \(pid), Name: \(name), Path: \(path)")
        }
    }
}

getProcesses()
