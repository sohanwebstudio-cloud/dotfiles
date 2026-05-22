pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: metrics

    property int    cpuPct:       0
    property int    memPct:       0
    property string memStr:       "0/64G"
    property string batPct:       "?"
    property string batStatus:    "?"
    property string netName:      "offline"
    property int    volPct:       0
    property bool   volMuted:     false
    property int    gpuPct:       0
    property int    gpuVram:      0
    property int    gpuVramTotal: 4096

    property var _proc: Process {
        command: ["/home/sohan/.config/quickshell/scripts/sysmon.sh"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    var d = JSON.parse(line)
                    metrics.cpuPct       = d.cpu  || 0
                    metrics.memPct       = d.mem  || 0
                    metrics.memStr       = (d.mu || "0") + "/" + (d.mt || "64") + "G"
                    metrics.batPct       = d.bat  || "?"
                    metrics.batStatus    = d.bs   || "?"
                    metrics.netName      = d.net  || "offline"
                    metrics.volPct       = d.vol  || 0
                    metrics.volMuted     = d.vm   || false
                    metrics.gpuPct       = d.gpu  || 0
                    metrics.gpuVram      = d.gv   || 0
                    metrics.gpuVramTotal = d.gvt  || 4096
                } catch(e) {}
            }
        }
    }
}
