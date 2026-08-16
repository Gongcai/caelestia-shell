#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class DesktopClockBackground : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, true)

public:
    explicit DesktopClockBackground(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopClockShadow : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(qreal, blur, 0.4)

public:
    explicit DesktopClockShadow(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopClock : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom-right"))
    CONFIG_PROPERTY(int, offsetX, 0)
    CONFIG_PROPERTY(int, offsetY, 0)
    CONFIG_PROPERTY(bool, invertColors, false)
    CONFIG_SUBOBJECT(DesktopClockBackground, background)
    CONFIG_SUBOBJECT(DesktopClockShadow, shadow)

public:
    explicit DesktopClock(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_background(new DesktopClockBackground(this))
        , m_shadow(new DesktopClockShadow(this)) {}
};

class DesktopMemoryBackground : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, true)

public:
    explicit DesktopMemoryBackground(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopMemory : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom-left"))
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(int, offsetX, 0)
    CONFIG_PROPERTY(int, offsetY, 0)
    CONFIG_PROPERTY(bool, animate, false)
    CONFIG_SUBOBJECT(DesktopMemoryBackground, background)

public:
    explicit DesktopMemory(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_background(new DesktopMemoryBackground(this)) {}
};

class DesktopVisualiserBackground : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(qreal, opacity, 0.7)
    CONFIG_PROPERTY(bool, blur, false)

public:
    explicit DesktopVisualiserBackground(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class DesktopVisualiser : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(QString, position, QStringLiteral("bottom-center"))
    CONFIG_PROPERTY(qreal, scale, 1.0)
    CONFIG_PROPERTY(int, offsetX, 0)
    CONFIG_PROPERTY(int, offsetY, 0)
    CONFIG_PROPERTY(int, bars, 24)
    CONFIG_SUBOBJECT(DesktopVisualiserBackground, background)

public:
    explicit DesktopVisualiser(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_background(new DesktopVisualiserBackground(this)) {}
};

class BackgroundVisualiser : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(bool, autoHide, true)
    CONFIG_PROPERTY(bool, blur, false)
    CONFIG_PROPERTY(qreal, rounding, 1)
    CONFIG_PROPERTY(qreal, spacing, 1)

public:
    explicit BackgroundVisualiser(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class BackgroundConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, wallpaperEnabled, true)
    // Empty means inherit the global wallpaper selection.
    CONFIG_PROPERTY(QString, wallpaperPath, QString())
    CONFIG_SUBOBJECT(DesktopClock, desktopClock)
    CONFIG_SUBOBJECT(DesktopMemory, desktopMemory)
    CONFIG_SUBOBJECT(DesktopVisualiser, desktopVisualiser)
    CONFIG_SUBOBJECT(BackgroundVisualiser, visualiser)

public:
    explicit BackgroundConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_desktopClock(new DesktopClock(this))
        , m_desktopMemory(new DesktopMemory(this))
        , m_desktopVisualiser(new DesktopVisualiser(this))
        , m_visualiser(new BackgroundVisualiser(this)) {}
};

} // namespace caelestia::config
