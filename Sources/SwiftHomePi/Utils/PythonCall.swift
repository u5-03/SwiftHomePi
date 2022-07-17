import Foundation
import PythonKit
import PathKit

struct PythonCall {
    func readNfcId() -> String {
        let sys = Python.import("sys")
        let path: String
        let readNfc: PythonObject
        #if os(Linux)
        // If on linux, `Path.current` returns repository path
        path = "\(Path.current)/Sources/SwiftHomePi"
        sys.path.append(path)
        readNfc = Python.import("read_nfc")
        #else
        // If on Mac, `Path.current` returns DerivedData path
        path = "\(Path.current)/SwiftHomePi_SwiftHomePi.bundle/Contents/Resources/"
        sys.path.append(path)
        readNfc = Python.import("read_nfc_mock")
        #endif

        return readNfc.read_id().description
    }
}
