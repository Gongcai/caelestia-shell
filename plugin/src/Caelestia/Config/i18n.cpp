#include "i18n.hpp"

#include <qcoreapplication.h>

namespace caelestia::config {

I18n::I18n(QObject* parent)
    : QObject(parent) {}

I18n* I18n::create(QQmlEngine* engine, QJSEngine*) {
    static I18n instance;
    instance.setEngine(engine);
    QQmlEngine::setObjectOwnership(&instance, QQmlEngine::CppOwnership);
    return &instance;
}

QString I18n::language() const {
    return m_language;
}

QString I18n::error() const {
    return m_error;
}

void I18n::setEngine(QQmlEngine* engine) {
    m_engine = engine;
    if (m_engine)
        m_engine->setUiLanguage(m_language);
}

void I18n::setError(const QString& error) {
    if (m_error == error)
        return;
    m_error = error;
    emit errorChanged();
}

void I18n::setLanguage(const QString& requestedLanguage) {
    const auto language = requestedLanguage.startsWith(QStringLiteral("zh"), Qt::CaseInsensitive)
                              ? QStringLiteral("zh_CN")
                              : QStringLiteral("en_US");

    if (m_translatorInstalled) {
        QCoreApplication::removeTranslator(&m_translator);
        m_translatorInstalled = false;
    }

    bool loaded = true;
    if (language == QStringLiteral("zh_CN")) {
        loaded = m_translator.load(QStringLiteral(":/caelestia/i18n/caelestia_zh_CN.qm"));
        if (loaded) {
            m_translatorInstalled = QCoreApplication::installTranslator(&m_translator);
            loaded = m_translatorInstalled;
        }
    }

    setError(loaded ? QString() : QStringLiteral("Failed to load the Simplified Chinese translation"));

    const bool changed = m_language != language;
    m_language = language;
    if (m_engine) {
        m_engine->setUiLanguage(language);
        m_engine->retranslate();
    }
    if (changed)
        emit languageChanged();
}

} // namespace caelestia::config
