require 'i18n'

module I18nLogging
  def translate(locale, key, options = EMPTY_HASH)
    Rails.logger.debug("Translate: #{locale}: #{key}")
    super
  end
end

module I18n::Backend
  class Simple
    prepend I18nLogging
  end
end
