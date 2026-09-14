#include "timezones.hpp"

#include <qlocale.h>
#include <qtimezone.h>

namespace caelestia::services {

bool TimeZones::isValid(const QString& id) const {
    return id == QStringLiteral("local") || QTimeZone::isTimeZoneIdAvailable(id.toUtf8());
}

QVariantMap TimeZones::at(
    const QString& id, const QDateTime& instant, const QString& language, bool twelveHourClock) const {
    const auto zone = id == QStringLiteral("local") ? QTimeZone::systemTimeZone() : QTimeZone(id.toUtf8());
    if (!zone.isValid() || !instant.isValid())
        return { { QStringLiteral("valid"), false } };

    const auto date = instant.toTimeZone(zone);
    const auto local = instant.toLocalTime();
    const auto time = date.time();
    const QLocale locale(language);
    return { { QStringLiteral("valid"), true }, { QStringLiteral("hours"), time.hour() },
        { QStringLiteral("minutes"), time.minute() }, { QStringLiteral("seconds"), time.second() },
        { QStringLiteral("time"),
            locale.toString(time, twelveHourClock ? QStringLiteral("h:mm") : QStringLiteral("HH:mm")) },
        { QStringLiteral("period"), time.hour() < 12 ? locale.amText() : locale.pmText() },
        { QStringLiteral("city"),
            QString::fromUtf8(zone.id()).section(QLatin1Char('/'), -1).replace(QLatin1Char('_'), QLatin1Char(' ')) },
        { QStringLiteral("abbreviation"), zone.abbreviation(instant) },
        { QStringLiteral("offsetSeconds"), zone.offsetFromUtc(instant) },
        { QStringLiteral("offsetMinutes"), (date.offsetFromUtc() - local.offsetFromUtc()) / 60 },
        { QStringLiteral("dayDifference"), local.date().daysTo(date.date()) },
        { QStringLiteral("daylight"), time.hour() >= 6 && time.hour() < 18 },
        { QStringLiteral("date"), locale.toString(date.date(), QLocale::ShortFormat) } };
}

} // namespace caelestia::services
