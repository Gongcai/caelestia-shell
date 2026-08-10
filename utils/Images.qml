pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]
    readonly property list<string> validVideoExtensions: ["mp4", "m4v", "webm", "mkv", "mov"]

    function isValidImageByName(name: string): bool {
        const lower = name.toLowerCase();
        return validImageExtensions.some(t => lower.endsWith(`.${t}`));
    }

    function isValidVideoByName(name: string): bool {
        const lower = name.toLowerCase();
        return validVideoExtensions.some(t => lower.endsWith(`.${t}`));
    }
}
