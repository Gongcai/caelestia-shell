pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string currentVideoPath: `${Paths.state}/wallpaper/video.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath: ""
    property string actualCurrent: ""
    property string video: ""
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        clearVideo();
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }

    function setWallpaper(path: string): void {
        if (Images.isValidVideoByName(path)) {
            setVideo(path);
            return;
        }
        clearVideo();
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function isVideoPath(path: string): bool {
        return Images.isValidVideoByName(path);
    }

    function pathForScreen(screen: string): string {
        const override = screen ? GlobalConfig.forScreen(screen).background.wallpaperPath : "";
        return String(override || video || current || fallback);
    }

    function setWallpaperForScreen(screen: string, path: string): void {
        if (!screen) {
            setWallpaper(path);
            return;
        }
        if (!Images.isValidImageByName(path) && !Images.isValidVideoByName(path)) {
            console.warn(`Unsupported wallpaper: ${path}`);
            return;
        }
        GlobalConfig.forScreen(screen).background.wallpaperPath = path;
    }

    function clearWallpaperForScreen(screen: string): void {
        if (screen)
            GlobalConfig.forScreen(screen).background.wallpaperPath = "";
    }

    function setRandomForScreen(screen: string): void {
        if (!screen || list.length === 0)
            return;
        const currentPath = pathForScreen(screen);
        const candidates = list.filter(entry => entry.path !== currentPath);
        const pool = candidates.length > 0 ? candidates : list;
        setWallpaperForScreen(screen, pool[Math.floor(Math.random() * pool.length)].path);
    }

    function setVideo(path: string): void {
        if (!Images.isValidVideoByName(path)) {
            console.warn(`Unsupported video wallpaper: ${path}`);
            return;
        }
        video = path;
        videoFile.setText(path);
    }

    function clearVideo(): void {
        if (!video && !videoFile.loaded)
            return;
        video = "";
        videoFile.setText("");
    }

    function preview(path: string): void {
        if (Images.isValidVideoByName(path)) {
            stopPreview();
            return;
        }
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function setVideo(path: string): void {
            root.setVideo(path);
        }

        function setForScreen(screen: string, path: string): void {
            root.setWallpaperForScreen(screen, path);
        }

        function clearForScreen(screen: string): void {
            root.clearWallpaperForScreen(screen);
        }

        function clearVideo(): void {
            root.clearVideo();
        }

        function getVideo(): string {
            return root.video;
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            root.clearVideo();
        }
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileView {
        id: videoFile

        path: root.currentVideoPath
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.video = text().trim()
        onLoadFailed: root.video = ""
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
