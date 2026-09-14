#pragma once

#include <qdatetime.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qvariantmap.h>

namespace caelestia::services {

class TimeZones : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    Q_INVOKABLE [[nodiscard]] bool isValid(const QString& id) const;
    Q_INVOKABLE [[nodiscard]] QVariantMap at(
        const QString& id, const QDateTime& instant, const QString& language, bool twelveHourClock) const;
};

} // namespace caelestia::services
