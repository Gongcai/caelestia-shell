pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.utils

Singleton {
    id: root

    // Set by the clipboard ipc handler so the panel only takes keyboard focus when it was
    // opened from a keybind, and not when it is dragged out from the screen edge.
    property bool focusOnOpen: false

    readonly property string thumbDir: `${Paths.cache}/clipboard/thumbs`
    readonly property string copyMarker: `${Paths.cache}/clipboard/copying`

    property var readyThumbs: ({})
    property var issuedThumbs: ({})
    property var pendingThumbs: []
    property bool reloadPending: false
    property int revision: 0
    property var list: []

    function query(search: string): var {
        const normalized = search.trim().replace(/\s+/g, " ").toLowerCase();
        if (!normalized)
            return [...root.list];
        return root.list.filter(item => item.preview.toLowerCase().includes(normalized));
    }

    // Keep the in-memory model synchronized after copying an existing entry.
    Timer {
        id: copyRefreshTimer

        interval: 300
        onTriggered: root.reload()
    }

    function reload(): void {
        if (listProc.running) {
            reloadPending = true;
            return;
        }

        reloadPending = false;
        listProc.running = true;
    }

    function copy(item: var, screenState: var): void {
        if (!item)
            return;

        const type = item.isImage ? ` --type image/${item.mimeType}` : "";
        Quickshell.execDetached(["sh", "-c", `mkdir -p "${Paths.cache}/clipboard" && printf '%s\n' "$$" > "${root.copyMarker}" && trap 'rm -f "${root.copyMarker}"' EXIT; cliphist decode ${item.id} | wl-copy${type}; sleep 0.5`]);
        copyRefreshTimer.restart();

        if (screenState)
            screenState.quickpanel = false;
    }

    function remove(item: var): void {
        Quickshell.execDetached(["cliphist", "delete", String(item.id)]);
        reload();
    }

    function wipe(): void {
        Quickshell.execDetached(["sh", "-c", `cliphist wipe && rm -rf "${root.thumbDir}"`]);
        root.readyThumbs = ({});
        root.issuedThumbs = ({});
        root.pendingThumbs = [];
        reload();
        Toaster.toast(qsTr("Clipboard cleared"), qsTr("The clipboard history has been wiped"), "delete_sweep", Toast.Success);
    }

    function thumbPath(item: var): string {
        return `${root.thumbDir}/${item.id}.png`;
    }

    function requestThumb(item: var): void {
        if (!item?.isImage || root.issuedThumbs[item.id])
            return;

        root.issuedThumbs[item.id] = true;
        root.pendingThumbs.push(item.id);
        root.pumpThumbs();
    }

    function pumpThumbs(): void {
        if (thumbProc.running || root.pendingThumbs.length === 0)
            return;

        const id = root.pendingThumbs[0];
        const dest = `${root.thumbDir}/${id}.png`;
        thumbProc.command = ["sh", "-c", `mkdir -p "${root.thumbDir}" && cliphist decode ${id} | magick - -auto-orient -thumbnail '160x120>' "png:${dest}"`];
        thumbProc.running = true;
    }

    // cliphist list outputs "<id>\t<preview>" lines, images look like
    // "[[ binary data 1 MiB png 1932x985 ]]"
    function parse(text: string): var {
        const out = [];

        for (const line of text.split("\n")) {
            if (!line)
                continue;

            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;

            const id = Number(line.slice(0, tab));
            if (!isFinite(id) || id <= 0)
                continue;

            const preview = line.slice(tab + 1);
            const bin = preview.match(/^\[\[ binary data (.+) (png|jpe?g|webp|gif) (\d+x\d+) \]\]$/);

            if (bin)
                out.push({
                    id,
                    preview,
                    isImage: true,
                    size: bin[1],
                    format: bin[2],
                    dimensions: bin[3],
                    mimeType: bin[2] === "jpg" ? "jpeg" : bin[2]
                });
            else
                out.push({
                    id,
                    preview,
                    isImage: false
                });
        }

        return out;
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = root.parse(text);
                root.revision++;
            }
        }

        onExited: {
            if (root.reloadPending)
                Qt.callLater(root.reload);
        }
    }

    Process {
        id: thumbProc

        running: false

        onExited: (exitCode, exitStatus) => {
            const id = root.pendingThumbs.shift();

            if (exitCode === 0) {
                const ready = Object.assign({}, root.readyThumbs);
                ready[id] = true;
                root.readyThumbs = ready;
            }

            root.pumpThumbs();
        }
    }

}
