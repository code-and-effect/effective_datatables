# Get the translations from:
# https://github.com/DataTables/Plugins/tree/master/i18n

require 'i18n_data'

(Dir['*'] - ['renamer.rb']).each do |f|
  code = I18nData.language_code(File.basename(f, ".*"))

  next if code.nil?

  File.rename(f, code.downcase + '.lang')
end