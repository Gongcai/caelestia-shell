#pragma once

#include <qobject.h>
#include <qpointer.h>
#include <qqmlengine.h>
#include <qtranslator.h>

namespace caelestia::config {

class I18n : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    static I18n* create(QQmlEngine* engine, QJSEngine*);

    [[nodiscard]] QString language() const;
    [[nodiscard]] QString error() const;
    void setLanguage(const QString& language);

signals:
    void languageChanged();
    void errorChanged();

private:
    explicit I18n(QObject* parent = nullptr);
    void setEngine(QQmlEngine* engine);
    void setError(const QString& error);

    QPointer<QQmlEngine> m_engine;
    QTranslator m_translator;
    QString m_language = QStringLiteral("en_US");
    QString m_error;
    bool m_translatorInstalled = false;
};

} // namespace caelestia::config
