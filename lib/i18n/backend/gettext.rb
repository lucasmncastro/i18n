require 'i18n/gettext'
require File.expand_path(File.dirname(__FILE__) + '/../../../vendor/po_parser.rb')

# Experimental support for using Gettext po files to store translations.
#
# To use this you can simply include the module to the Simple backend - or
# whatever other backend you are using.
#
#   I18n::Backend::Simple.send(:include, I18n::Backend::Gettext)
#
# Now you should be able to include your Gettext translation (*.po) files to
# the I18n.load_path so they're loaded to the backend and you can use them as
# usual:
#
#  I18n.load_path += Dir["path/to/locales/*.po"]
#
# Following the Gettext convention this implementation expects that your
# translation files are named by their locales. E.g. the file en.po would
# contain the translations for the English locale.
module I18n
  module Backend
    module Gettext
      class PoData < Hash
        def set_comment(msgid_or_sym, comment)
          # ignore
        end
      end

      protected
        def load_po(filename)
          locale = ::File.basename(filename, '.po').to_sym
          data = normalize(locale, parse(filename))
          { locale => data }
        end

        def parse(filename)
          GetText::PoParser.new.parse(::File.read(filename), PoData.new)
        end

        def normalize(locale, data)
          data.inject({}) do |result, (key, value)|
            key, value = normalize_pluralization(locale, key, value) if key.index("\000")
            result[key] = value
            result
          end
        end

        def normalize_pluralization(locale, key, value)
          # FIXME po_parser includes \000 chars that can not be turned into Symbols
          key = key.dup.gsub("\000", I18n::Gettext::PLURAL_SEPARATOR)

          keys = I18n::Gettext.plural_keys(locale)
          values = value.split("\000")
          raise "invalid number of plurals: #{values.size}, keys: #{keys.inspect}" if values.size != keys.size

          result = {}
          values.each_with_index { |value, ix| result[keys[ix]] = value }
          [key, result]
        end

    end
  end
end
