#pragma once

#include <qabstractitemmodel.h>
#include <qqmlintegration.h>
#include <qstringlist.h>
#include <qtimer.h>

class QDBusPendingCallWatcher;
class QDBusServiceWatcher;

namespace caelestia::services {

class KdeConnect : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int deviceCount READ rowCount NOTIFY deviceCountChanged)
    Q_PROPERTY(int connectedCount READ connectedCount NOTIFY connectedCountChanged)

public:
    enum Role {
        DeviceIdRole = Qt::UserRole + 1,
        NameRole,
        TypeRole,
        IconNameRole,
        ReachableRole,
        PairedRole,
        PairRequestedRole,
        PairRequestedByPeerRole,
        BatteryChargeRole,
        BatteryChargingRole,
        PluginsRole,
    };
    Q_ENUM(Role)

    explicit KdeConnect(QObject* parent = nullptr);

    [[nodiscard]] bool available() const;
    [[nodiscard]] int connectedCount() const;

    [[nodiscard]] int rowCount(const QModelIndex& parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex& index, int role) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

public slots:
    void refresh();

public:
    Q_INVOKABLE void requestPairing(const QString& deviceId);
    Q_INVOKABLE void acceptPairing(const QString& deviceId);
    Q_INVOKABLE void cancelPairing(const QString& deviceId);
    Q_INVOKABLE void unpair(const QString& deviceId);
    Q_INVOKABLE void ping(const QString& deviceId);
    Q_INVOKABLE void ring(const QString& deviceId);
    Q_INVOKABLE void sendClipboard(const QString& deviceId);
    Q_INVOKABLE void sendFile(const QString& deviceId, const QString& path);

signals:
    void availableChanged();
    void deviceCountChanged();
    void connectedCountChanged();
    void operationFinished(bool success, const QString& message);

private:
    struct Device {
        QString id;
        QString name;
        QString type;
        QString iconName;
        bool reachable = false;
        bool paired = false;
        bool pairRequested = false;
        bool pairRequestedByPeer = false;
        int batteryCharge = -1;
        bool batteryCharging = false;
        QStringList plugins;

        bool operator==(const Device&) const = default;
    };

    [[nodiscard]] static QString devicePath(const QString& deviceId);
    [[nodiscard]] static QVariantMap properties(const QString& path, const QString& interface);
    [[nodiscard]] static bool validDeviceId(const QString& deviceId);

    void setAvailable(bool available);
    void callDevice(const QString& deviceId, const QString& method, const QString& successMessage);
    void callPlugin(const QString& deviceId, const QString& plugin, const QString& method,
        const QString& successMessage);
    void watchCall(QDBusPendingCallWatcher* watcher, const QString& successMessage);

    QList<Device> m_devices;
    QTimer m_refreshTimer;
    QDBusServiceWatcher* m_serviceWatcher = nullptr;
    bool m_available = false;
    int m_connectedCount = 0;
};

} // namespace caelestia::services
