#include "kdeconnect.hpp"

#include <qdbusconnection.h>
#include <qdbusconnectioninterface.h>
#include <qdbusinterface.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbusreply.h>
#include <qdbusservicewatcher.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qregularexpression.h>
#include <qurl.h>

namespace caelestia::services {

namespace {

constexpr auto Service = "org.kde.kdeconnect";
constexpr auto DaemonPath = "/modules/kdeconnect";
constexpr auto DaemonInterface = "org.kde.kdeconnect.daemon";
constexpr auto DeviceInterface = "org.kde.kdeconnect.device";

} // namespace

KdeConnect::KdeConnect(QObject* parent)
    : QAbstractListModel(parent)
    , m_serviceWatcher(new QDBusServiceWatcher(QString::fromLatin1(Service), QDBusConnection::sessionBus(),
          QDBusServiceWatcher::WatchForRegistration | QDBusServiceWatcher::WatchForUnregistration, this)) {
    m_refreshTimer.setInterval(2500);
    m_refreshTimer.setSingleShot(false);

    connect(&m_refreshTimer, &QTimer::timeout, this, &KdeConnect::refresh);
    connect(m_serviceWatcher, &QDBusServiceWatcher::serviceRegistered, this, [this] {
        setAvailable(true);
        refresh();
    });
    connect(m_serviceWatcher, &QDBusServiceWatcher::serviceUnregistered, this, [this] {
        setAvailable(false);
        if (!m_devices.isEmpty()) {
            beginResetModel();
            m_devices.clear();
            endResetModel();
            m_connectedCount = 0;
            emit deviceCountChanged();
            emit connectedCountChanged();
        }
    });

    auto bus = QDBusConnection::sessionBus();
    bus.connect(QString::fromLatin1(Service), QString::fromLatin1(DaemonPath),
        QString::fromLatin1(DaemonInterface), QStringLiteral("deviceListChanged"), this, SLOT(refresh()));
    bus.connect(QString::fromLatin1(Service), QString::fromLatin1(DaemonPath),
        QString::fromLatin1(DaemonInterface), QStringLiteral("pairingRequestsChanged"), this, SLOT(refresh()));

    setAvailable(bus.interface()->isServiceRegistered(QString::fromLatin1(Service)));
    m_refreshTimer.start();
    refresh();
}

bool KdeConnect::available() const {
    return m_available;
}

int KdeConnect::connectedCount() const {
    return m_connectedCount;
}

int KdeConnect::rowCount(const QModelIndex& parent) const {
    return parent.isValid() ? 0 : static_cast<int>(m_devices.size());
}

QVariant KdeConnect::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_devices.size()) {
        return {};
    }

    const auto& device = m_devices.at(index.row());
    switch (role) {
    case DeviceIdRole:
        return device.id;
    case NameRole:
        return device.name;
    case TypeRole:
        return device.type;
    case IconNameRole:
        return device.iconName;
    case ReachableRole:
        return device.reachable;
    case PairedRole:
        return device.paired;
    case PairRequestedRole:
        return device.pairRequested;
    case PairRequestedByPeerRole:
        return device.pairRequestedByPeer;
    case BatteryChargeRole:
        return device.batteryCharge;
    case BatteryChargingRole:
        return device.batteryCharging;
    case PluginsRole:
        return device.plugins;
    default:
        return {};
    }
}

QHash<int, QByteArray> KdeConnect::roleNames() const {
    return {
        { DeviceIdRole, "deviceId" },
        { NameRole, "name" },
        { TypeRole, "deviceType" },
        { IconNameRole, "iconName" },
        { ReachableRole, "reachable" },
        { PairedRole, "paired" },
        { PairRequestedRole, "pairRequested" },
        { PairRequestedByPeerRole, "pairRequestedByPeer" },
        { BatteryChargeRole, "batteryCharge" },
        { BatteryChargingRole, "batteryCharging" },
        { PluginsRole, "plugins" },
    };
}

void KdeConnect::refresh() {
    const auto bus = QDBusConnection::sessionBus();
    const bool registered = bus.interface()->isServiceRegistered(QString::fromLatin1(Service));
    setAvailable(registered);
    if (!registered) {
        return;
    }

    QDBusInterface daemon(QString::fromLatin1(Service), QString::fromLatin1(DaemonPath),
        QString::fromLatin1(DaemonInterface), bus);
    const QDBusReply<QStringList> ids = daemon.call(QStringLiteral("devices"), false, false);
    if (!ids.isValid()) {
        return;
    }

    QList<Device> devices;
    devices.reserve(ids.value().size());
    int connected = 0;
    for (const QString& id : ids.value()) {
        const QString path = devicePath(id);
        const QVariantMap props = properties(path, QString::fromLatin1(DeviceInterface));
        if (props.isEmpty()) {
            continue;
        }

        Device device;
        device.id = id;
        device.name = props.value(QStringLiteral("name"), id).toString();
        device.type = props.value(QStringLiteral("type"), QStringLiteral("device")).toString();
        device.iconName = props.value(QStringLiteral("iconName"), QStringLiteral("smartphone")).toString();
        device.reachable = props.value(QStringLiteral("isReachable")).toBool();
        device.paired = props.value(QStringLiteral("isPaired")).toBool();
        device.pairRequested = props.value(QStringLiteral("isPairRequested")).toBool();
        device.pairRequestedByPeer = props.value(QStringLiteral("isPairRequestedByPeer")).toBool();

        QDBusInterface deviceIface(QString::fromLatin1(Service), path, QString::fromLatin1(DeviceInterface), bus);
        const QDBusReply<QStringList> plugins = deviceIface.call(QStringLiteral("loadedPlugins"));
        if (plugins.isValid()) {
            device.plugins = plugins.value();
        }

        if (device.reachable) {
            ++connected;
            const QVariantMap battery = properties(path + QStringLiteral("/battery"),
                QStringLiteral("org.kde.kdeconnect.device.battery"));
            device.batteryCharge = battery.value(QStringLiteral("charge"), -1).toInt();
            device.batteryCharging = battery.value(QStringLiteral("isCharging")).toBool();
        }

        devices.push_back(std::move(device));
    }

    if (devices != m_devices) {
        const int oldCount = static_cast<int>(m_devices.size());
        beginResetModel();
        m_devices = std::move(devices);
        endResetModel();
        if (oldCount != m_devices.size()) {
            emit deviceCountChanged();
        }
    }

    if (connected != m_connectedCount) {
        m_connectedCount = connected;
        emit connectedCountChanged();
    }
}

void KdeConnect::requestPairing(const QString& deviceId) {
    callDevice(deviceId, QStringLiteral("requestPairing"), tr("Pairing request sent"));
}

void KdeConnect::acceptPairing(const QString& deviceId) {
    callDevice(deviceId, QStringLiteral("acceptPairing"), tr("Pairing accepted"));
}

void KdeConnect::cancelPairing(const QString& deviceId) {
    callDevice(deviceId, QStringLiteral("cancelPairing"), tr("Pairing cancelled"));
}

void KdeConnect::unpair(const QString& deviceId) {
    callDevice(deviceId, QStringLiteral("unpair"), tr("Device unpaired"));
}

void KdeConnect::ping(const QString& deviceId) {
    callPlugin(deviceId, QStringLiteral("ping"), QStringLiteral("sendPing"), tr("Ping sent"));
}

void KdeConnect::ring(const QString& deviceId) {
    callPlugin(deviceId, QStringLiteral("findmyphone"), QStringLiteral("ring"), tr("Phone is ringing"));
}

void KdeConnect::sendClipboard(const QString& deviceId) {
    callPlugin(deviceId, QStringLiteral("clipboard"), QStringLiteral("sendClipboard"), tr("Clipboard sent"));
}

void KdeConnect::sendFile(const QString& deviceId, const QString& path) {
    if (!validDeviceId(deviceId)) {
        emit operationFinished(false, tr("Invalid device"));
        return;
    }

    const QString localPath = QUrl(path).isLocalFile() ? QUrl(path).toLocalFile() : path;
    if (!QFileInfo::exists(localPath)) {
        emit operationFinished(false, tr("File does not exist"));
        return;
    }

    auto* process = new QProcess(this);
    process->setProgram(QStringLiteral("kdeconnect-cli"));
    process->setArguments({ QStringLiteral("--device"), deviceId, QStringLiteral("--share"), localPath });
    connect(process, &QProcess::finished, this, [this, process](int code, QProcess::ExitStatus status) {
        const QString error = QString::fromUtf8(process->readAllStandardError()).trimmed();
        if (status == QProcess::NormalExit && code == 0) {
            emit operationFinished(true, tr("File sent"));
        } else {
            emit operationFinished(false, error.isEmpty() ? tr("Unable to send file") : error);
        }
        process->deleteLater();
    });
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            emit operationFinished(false, tr("kdeconnect-cli is unavailable"));
            process->deleteLater();
        }
    });
    process->start();
}

QString KdeConnect::devicePath(const QString& deviceId) {
    return QStringLiteral("/modules/kdeconnect/devices/") + deviceId;
}

QVariantMap KdeConnect::properties(const QString& path, const QString& interface) {
    QDBusInterface props(QString::fromLatin1(Service), path, QStringLiteral("org.freedesktop.DBus.Properties"),
        QDBusConnection::sessionBus());
    const QDBusReply<QVariantMap> reply = props.call(QStringLiteral("GetAll"), interface);
    return reply.isValid() ? reply.value() : QVariantMap {};
}

bool KdeConnect::validDeviceId(const QString& deviceId) {
    static const QRegularExpression valid(QStringLiteral("^[A-Za-z0-9_-]+$"));
    return valid.match(deviceId).hasMatch();
}

void KdeConnect::setAvailable(bool available) {
    if (m_available == available) {
        return;
    }
    m_available = available;
    emit availableChanged();
}

void KdeConnect::callDevice(const QString& deviceId, const QString& method, const QString& successMessage) {
    if (!validDeviceId(deviceId)) {
        emit operationFinished(false, tr("Invalid device"));
        return;
    }

    QDBusMessage message = QDBusMessage::createMethodCall(QString::fromLatin1(Service), devicePath(deviceId),
        QString::fromLatin1(DeviceInterface), method);
    auto* watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message), this);
    watchCall(watcher, successMessage);
}

void KdeConnect::callPlugin(const QString& deviceId, const QString& plugin, const QString& method,
    const QString& successMessage) {
    if (!validDeviceId(deviceId)) {
        emit operationFinished(false, tr("Invalid device"));
        return;
    }

    const QString interface = QStringLiteral("org.kde.kdeconnect.device.") + plugin;
    QDBusMessage message = QDBusMessage::createMethodCall(QString::fromLatin1(Service),
        devicePath(deviceId) + QLatin1Char('/') + plugin, interface, method);
    auto* watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message), this);
    watchCall(watcher, successMessage);
}

void KdeConnect::watchCall(QDBusPendingCallWatcher* watcher, const QString& successMessage) {
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, successMessage] {
        if (watcher->isError()) {
            emit operationFinished(false, watcher->error().message());
        } else {
            emit operationFinished(true, successMessage);
        }
        watcher->deleteLater();
        QTimer::singleShot(150, this, &KdeConnect::refresh);
    });
}

} // namespace caelestia::services
