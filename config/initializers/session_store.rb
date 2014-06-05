# Be sure to restart your server when you modify this file.

Poirot::Application.config.session_store :cookie_store, { key: '_poirot_session', secure: Settings.protocol.eql?("https") }
